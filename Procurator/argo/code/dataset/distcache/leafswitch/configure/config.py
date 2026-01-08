
PUTREQ           = 0x0001
DELREQ           = 0x0002
GETREQ           = 0x0030
PUTREQ_INSWITCH  = 0x0005
DELREQ_INSWITCH  = 0x0014
GETREQ_INSWITCH  = 0x0004
CACHE_POP_INSWITCH       = 0x007f
NETCACHE_VALUEUPDATE      = 0x003b
# etc... fill others if needed

class ExpandedLeafConfig:
    def __init__(self, outfile="leaf_expanded_entries.txt"):
        self.outfile = outfile
        self.lines = []

    def table_set_default(self, tbl, action, params=None):
        if params:
            line = f"table_set_default {tbl} {action} {' '.join(params)}"
        else:
            line = f"table_set_default {tbl} {action}"
        self.lines.append(line)

    def table_add(self, tbl, action, match, params=None):
        match_str = " ".join(str(m) for m in match)
        if params:
            param_str = " ".join(str(p) for p in params)
            line = f"table_add {tbl} {action} {match_str} => {param_str}"
        else:
            line = f"table_add {tbl} {action} {match_str} =>"
        self.lines.append(line)

    ### ============== Ingress tables ==============
    def config_l2l3_forward_tbl(self):
        self.lines.append("# --- l2l3_forward_tbl ---")
        self.table_set_default("l2l3_forward_tbl", "_nop")
        # for example: if IP=10.0.3.1 => eport=1
        self.table_add("l2l3_forward_tbl", "l2l3_forward", ["10.0.3.1/32"], ["1"])
        # if IP=10.0.1.1 => eport=2
        self.table_add("l2l3_forward_tbl", "l2l3_forward", ["10.0.1.1/32"], ["2"])

    def config_set_hot_threshold_tbl(self):
        self.lines.append("# --- set_hot_threshold_tbl ---")
        # if you want to enable is_hot detection, set default to set_hot_threshold(1024) for example
        self.table_set_default("set_hot_threshold_tbl", "set_hot_threshold", [hex(1024)])

    def config_hash_for_partition_tbl(self):
        self.lines.append("# --- hash_for_partition_tbl ---")
        self.table_set_default("hash_for_partition_tbl", "_nop")
        for op in [PUTREQ, DELREQ, GETREQ]:
            self.table_add("hash_for_partition_tbl", "hash_for_partition", [hex(op)])

    def config_hash_partition_tbl(self):
        self.lines.append("# --- hash_partition_tbl ---")
        self.table_set_default("hash_partition_tbl", "_nop")
        # e.g. [op, 0->1023] => set udp_dstPort=5678, egress=1
        for op in [PUTREQ, DELREQ, GETREQ]:
            self.table_add("hash_partition_tbl", "hash_partition",
                           [hex(op), "0->1023"], [hex(5678), "1"])

    def config_hash_spine_partition_tbl(self):
        self.lines.append("# --- hash_spine_partition_tbl ---")
        self.table_set_default("hash_spine_partition_tbl", "_nop")
        # If you also want to send some ops to spine:
        self.table_add("hash_spine_partition_tbl", "hash_spine_partition",
                       [hex(CACHE_POP_INSWITCH), "0->1023"], ["0x33", "2"])

    def config_cache_lookup_tbl(self):
        self.lines.append("# --- cache_lookup_tbl ---")
        self.table_set_default("cache_lookup_tbl", "uncached_action")
        # example key
        self.table_add("cache_lookup_tbl", "cached_action",
                       ["0x11111111","0x22222222","0x33333333","0x44444444","0x55555555"],
                       ["7"])

    def config_hash_for_seq_tbl(self):
        self.lines.append("# --- hash_for_seq_tbl ---")
        self.table_set_default("hash_for_seq_tbl", "_nop")
        # e.g. for PUT/DEL we do a seq hash
        for op in [PUTREQ, DELREQ]:
            self.table_add("hash_for_seq_tbl", "hash_for_seq", [hex(op)])

    def config_prepare_for_cachehit_tbl(self):
        self.lines.append("# --- prepare_for_cachehit_tbl ---")
        self.table_set_default("prepare_for_cachehit_tbl", "set_client_sid", ["0"])
        # example: if GETREQ from 10.0.1.1 => set_client_sid(100)
        self.table_add("prepare_for_cachehit_tbl", "set_client_sid",
                       [hex(GETREQ), "10.0.1.1/32"], [hex(100)])

    def config_ipv4_forward_tbl(self):
        self.lines.append("# --- ipv4_forward_tbl ---")
        self.table_set_default("ipv4_forward_tbl", "_nop")
        # if GETRES, dstIP=10.0.1.1 => egress=2
        self.table_add("ipv4_forward_tbl", "forward_normal_response",
                       [hex(0x09), "10.0.1.1/32"], ["2"])

    def config_sample_tbl(self):
        self.lines.append("# --- sample_tbl ---")
        self.table_set_default("sample_tbl", "_nop")
        # for CM freq usage; if GETREQ => sample
        self.table_add("sample_tbl", "sample", [hex(GETREQ)])

    def config_ig_port_forward_tbl(self):
        self.lines.append("# --- ig_port_forward_tbl ---")
        self.table_set_default("ig_port_forward_tbl", "_nop")
        # if GETREQ => update_getreq_to_getreq_inswitch
        self.table_add("ig_port_forward_tbl", "update_getreq_to_getreq_inswitch", [hex(GETREQ)])
        # if PUTREQ => ...
        self.table_add("ig_port_forward_tbl", "update_putreq_to_putreq_inswitch", [hex(PUTREQ)])
        # etc.

    ### ============== Egress tables ==============
    def config_bypass_egress_tbl(self):
        self.lines.append("# --- bypass_egress_tbl ---")
        self.table_set_default("bypass_egress_tbl", "_nop")
        # e.g. if op=NETCACHE_VALUEUPDATE & spine_sid=0 => set_bypass_egress
        self.table_add("bypass_egress_tbl", "set_bypass_egress", [hex(NETCACHE_VALUEUPDATE), hex(0)])

    def config_access_latest_tbl(self):
        self.lines.append("# --- access_latest_tbl ---")
        self.table_set_default("access_latest_tbl", "reset_is_latest")
        # e.g. if GETREQ_INSWITCH & is_cached=1 => get_latest
        self.table_add("access_latest_tbl", "get_latest", [hex(GETREQ_INSWITCH), "1", "0"])

    def config_access_seq_tbl(self):
        self.lines.append("# --- access_seq_tbl ---")
        self.table_set_default("access_seq_tbl", "_nop")
        # if PUTREQ_INSWITCH & fragidx=0 => assign_seq
        self.table_add("access_seq_tbl", "assign_seq", [hex(PUTREQ_INSWITCH), "0"])

    def config_save_client_udpport_tbl(self):
        self.lines.append("# --- save_client_udpport_tbl ---")
        self.table_set_default("save_client_udpport_tbl", "_nop")
        # e.g. if GETREQ_INSWITCH => save_client_udpport
        self.table_add("save_client_udpport_tbl", "save_client_udpport", [hex(GETREQ_INSWITCH)])

    def config_prepare_for_cachepop_tbl(self):
        self.lines.append("# --- prepare_for_cachepop_tbl ---")
        self.table_set_default("prepare_for_cachepop_tbl", "reset_server_sid")
        # e.g. if GETREQ_INSWITCH, egress_port=1 => set_server_sid_and_port(77)
        self.table_add("prepare_for_cachepop_tbl", "set_server_sid_and_port",
                       [hex(GETREQ_INSWITCH), "1"], [hex(77)])

    def config_is_hot_tbl(self):
        self.lines.append("# --- is_hot_tbl ---")
        self.table_set_default("is_hot_tbl", "reset_is_hot")
        # if cm1_predicate=1, cm2_predicate=1, cm3_predicate=1, cm4_predicate=1 => set_is_hot
        self.table_add("is_hot_tbl", "set_is_hot", ["1","1","1","1"])

    def config_access_cache_frequency_tbl(self):
        self.lines.append("# --- access_cache_frequency_tbl ---")
        self.table_set_default("access_cache_frequency_tbl", "_nop")
        # e.g. if GETREQ_INSWITCH & is_sampled=1 & is_cached=0 & is_latest=0 => update_cache_frequency
        self.table_add("access_cache_frequency_tbl", "update_cache_frequency",
                       [hex(GETREQ_INSWITCH),"1","0","0"])

    def config_access_deleted_tbl(self):
        self.lines.append("# --- access_deleted_tbl ---")
        self.table_set_default("access_deleted_tbl", "reset_is_deleted")
        # e.g. if GETREQ_INSWITCH & is_cached=1 & is_latest=1 & stat=0 => get_deleted
        self.table_add("access_deleted_tbl", "get_deleted", [hex(GETREQ_INSWITCH),"1","1","0"])
        # if DELREQ_INSWITCH & is_cached=1 => set_and_get_deleted
        self.table_add("access_deleted_tbl", "set_and_get_deleted", [hex(DELREQ_INSWITCH),"1","1","0"])

    def config_access_savedseq_tbl(self):
        self.lines.append("# --- access_savedseq_tbl ---")
        self.table_set_default("access_savedseq_tbl", "_nop")
        # e.g. if CACHE_POP_INSWITCH & is_cached=1 & is_latest=1 => set_and_get_savedseq
        self.table_add("access_savedseq_tbl", "set_and_get_savedseq",
                       [hex(CACHE_POP_INSWITCH), "1", "1"])

    def config_update_vallen_tbl(self):
        self.lines.append("# --- update_vallen_tbl ---")
        self.table_set_default("update_vallen_tbl", "reset_access_val_mode")
        # e.g. if GETREQ_INSWITCH & is_cached=1 & is_latest=1 => get_vallen
        self.table_add("update_vallen_tbl", "get_vallen", [hex(GETREQ_INSWITCH),"1","1"])
        # if CACHE_POP_INSWITCH => set_and_get_vallen
        self.table_add("update_vallen_tbl", "set_and_get_vallen", [hex(CACHE_POP_INSWITCH),"1","1"])

    def config_is_report_tbl(self):
        self.lines.append("# --- is_report_tbl ---")
        self.table_set_default("is_report_tbl", "reset_is_report")
        # e.g. if is_report1=1, is_report2=1, is_report3=1 => set_is_report
        self.table_add("is_report_tbl", "set_is_report", ["1","1","1"])

    def config_lastclone_lastscansplit_tbl(self):
        self.lines.append("# --- lastclone_lastscansplit_tbl ---")
        self.table_set_default("lastclone_lastscansplit_tbl", "reset_is_lastclone_lastscansplit")
        # if NETCACHE_GETREQ_POP & clonenum_for_pktloss=0 => set_is_lastclone
        self.table_add("lastclone_lastscansplit_tbl", "set_is_lastclone",
                       [hex(0x0120), "0"])

    def config_eg_port_forward_tbl(self):
        self.lines.append("# --- eg_port_forward_tbl ---")
        self.table_set_default("eg_port_forward_tbl", "_nop")
        # e.g. if GETREQ_INSWITCH & is_cached=1 & is_latest=1 => update_getreq_inswitch_to_getres_by_mirroring
        self.table_add("eg_port_forward_tbl", "update_getreq_inswitch_to_getres_by_mirroring",
                       [hex(GETREQ_INSWITCH),"1","0","0","1","0","100","0","0"],
                       ["100","123","0"])

    def config_update_ipmac_srcport_tbl(self):
        self.lines.append("# --- update_ipmac_srcport_tbl ---")
        self.table_set_default("update_ipmac_srcport_tbl", "_nop")
        # e.g. if GETRES & egress=2 => update_ipmac_srcport_server2client
        self.table_add("update_ipmac_srcport_tbl", "update_ipmac_srcport_server2client",
                       [hex(0x09),"2"], ["0x001122334455","0x00aabbccddeeff",
                                         "10.0.1.1","10.0.2.1","0x1234"])

    def config_update_pktlen_tbl(self):
        self.lines.append("# --- update_pktlen_tbl ---")
        self.table_set_default("update_pktlen_tbl", "_nop")
        # if GETRES & vallen in range 0->1024 => update_pktlen(34,54)
        self.table_add("update_pktlen_tbl", "update_pktlen", [hex(0x09),"0->1024"], ["34","54"])

    def config_add_and_remove_value_header_tbl(self):
        self.lines.append("# --- add_and_remove_value_header_tbl ---")
        self.table_set_default("add_and_remove_value_header_tbl", "remove_all")
        # e.g. if GETRES & vallen=1->8 => add_to_val1
        self.table_add("add_and_remove_value_header_tbl", "add_to_val1", [hex(0x09),"1->8"])

    def config_update_val_lohi_tbl(self):
        self.lines.append("# --- update_vallo1_tbl / update_valhi1_tbl ... ---")
        # Usually default: NoAction
        self.table_set_default("update_vallo1_tbl","NoAction")
        self.table_set_default("update_valhi1_tbl","NoAction")
        # if meta.access_val_mode=1 => get_vallo1
        self.table_add("update_vallo1_tbl", "get_vallo1", ["1"])
        self.table_add("update_valhi1_tbl", "get_valhi1", ["1"])

    ### ============== MAIN RUN ==============
    def run_config(self):
        # Ingress
        self.config_l2l3_forward_tbl()
        self.config_set_hot_threshold_tbl()
        self.config_hash_for_partition_tbl()
        self.config_hash_partition_tbl()
        self.config_hash_spine_partition_tbl()
        self.config_cache_lookup_tbl()
        self.config_hash_for_seq_tbl()
        self.config_prepare_for_cachehit_tbl()
        self.config_ipv4_forward_tbl()
        self.config_sample_tbl()
        self.config_ig_port_forward_tbl()

        # Egress
        self.config_bypass_egress_tbl()
        self.config_access_latest_tbl()
        self.config_access_seq_tbl()
        self.config_save_client_udpport_tbl()
        self.config_prepare_for_cachepop_tbl()
        self.config_is_hot_tbl()
        self.config_access_cache_frequency_tbl()
        self.config_access_deleted_tbl()
        self.config_access_savedseq_tbl()
        self.config_update_vallen_tbl()
        self.config_is_report_tbl()
        self.config_lastclone_lastscansplit_tbl()
        self.config_eg_port_forward_tbl()
        self.config_update_ipmac_srcport_tbl()
        self.config_update_pktlen_tbl()
        self.config_add_and_remove_value_header_tbl()
        self.config_update_val_lohi_tbl()

        with open(self.outfile,"w") as f:
            for line in self.lines:
                f.write(line+"\n")

def main():
    cfg = ExpandedLeafConfig()
    cfg.run_config()
    print(f"Generated config: {cfg.outfile}")

if __name__=="__main__":
    main()