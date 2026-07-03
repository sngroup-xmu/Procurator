#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Example script to generate table entries for the 'Spine' switch in DistCache,
including some additional tables: prepare_for_cachehit_tbl, eg_port_forward_tbl,
access_deleted_tbl, access_cache_frequency_tbl, etc.
Adjust IPs / operation codes / egress ports according to your topology and macros.
"""

# 一些宏定义，可与 P4 中保持一致
PUTREQ = 0x0001       # #define PUTREQ 0x0001
DELREQ = 0x0002       # #define DELREQ 0x0002
GETREQ = 0x0030       # #define GETREQ 0x0030
GETREQ_SPINE = 0x0200 # #define GETREQ_SPINE 0x0200 (若需要)
GETRES = 0x0009       # #define GETRES 0x09

def main():
    # =============== l2l3_forward_tbl ===============
    print("# --------------- l2l3_forward_tbl ---------------")
    print("table_set_default l2l3_forward_tbl _drop")
    print("table_add l2l3_forward_tbl l2l3_forward 10.0.2.1/32 => 1")  # Spine->Leaf
    print("table_add l2l3_forward_tbl l2l3_forward 10.0.1.1/32 => 2")  # Spine->ClientTrack

    # =============== hash_for_partition_tbl ===============
    print("# --------------- hash_for_partition_tbl ---------------")
    print("table_set_default hash_for_partition_tbl _nop")
    print(f"table_add hash_for_partition_tbl hash_for_partition {hex(PUTREQ)} =>")
    print(f"table_add hash_for_partition_tbl hash_for_partition {hex(DELREQ)} =>")

    # =============== hash_leaf_partition_tbl ===============
    print("# --------------- hash_leaf_partition_tbl ---------------")
    print("table_set_default hash_leaf_partition_tbl _nop")
    print(f"table_add hash_leaf_partition_tbl hash_leaf_partition {hex(PUTREQ)} 0->1023 => 1")
    print(f"table_add hash_leaf_partition_tbl hash_leaf_partition {hex(DELREQ)} 0->1023 => 1")

    # =============== ipv4_forward_tbl ===============
    print("# --------------- ipv4_forward_tbl ---------------")
    print("table_set_default ipv4_forward_tbl _drop")
    print(f"table_add ipv4_forward_tbl forward_normal_response {hex(GETREQ)} 10.0.1.1/32 => 2")

    # =============== set_spine_tbl ===============
    print("# --------------- set_spine_tbl ---------------")
    print("table_set_default set_spine_tbl NoAction")
    # 对 GETREQ (0x30) 做缓存查找时，需要将 meta.is_spine = 1
    print(f"table_add set_spine_tbl set_spine {hex(GETREQ)} =>")

    # =============== cache_lookup_tbl ===============
    print("# --------------- cache_lookup_tbl ---------------")
    print("table_set_default cache_lookup_tbl uncached_action")
    # 如果要在 spine 缓存中预置一个 key (示例):
    key_lolo   = 0x11111111
    key_lohi   = 0x22222222
    key_hilo   = 0x33333333
    key_hihilo = 0x44444444
    key_hihihi = 0x55555555
    idx_for_cache = 10  # 随意示例
    print(f"table_add cache_lookup_tbl cached_action {hex(key_lolo)} {hex(key_lohi)} {hex(key_hilo)} {hex(key_hihilo)} {hex(key_hihihi)} => {idx_for_cache}")

    # =============== prepare_for_cachehit_tbl ===============
    print("# --------------- prepare_for_cachehit_tbl ---------------")
    # key = { hdr.op_hdr.optype: exact; hdr.ipv4_hdr.srcAddr: lpm; }
    # actions = { set_client_sid; NoAction; }
    # default_action = set_client_sid(0);
    # 用于在 meta 中设置 client_sid，以便后续 egress pipeline 中 clone 给客户端
    print("table_set_default prepare_for_cachehit_tbl set_client_sid 0")
    # 例如：若 GETREQ 来自 10.0.1.0/24，设置 client_sid=111
    print(f"table_add prepare_for_cachehit_tbl set_client_sid {hex(GETREQ)} 10.0.1.0/24 => 111")

    # =============== eg_port_forward_tbl ===============
    print("# --------------- eg_port_forward_tbl ---------------")
    # key = { hdr.op_hdr.optype: exact; meta.is_cached: exact; }
    # actions = { update_netcache_getreq_spine_to_getreq; update_netcache_getreq_spine_to_getres_by_mirroring; NoAction; }
    print("table_set_default eg_port_forward_tbl NoAction")
    # 若 GETREQ & 命中缓存 => 直接改成 GETRES 并镜像给 client
    print(f"table_add eg_port_forward_tbl update_netcache_getreq_spine_to_getres_by_mirroring {hex(GETREQ)} 1 => 0x0")
    # 若 GETREQ & 未命中缓存 => 保持为 GETREQ, 继续发往后端/Leaf
    print(f"table_add eg_port_forward_tbl update_netcache_getreq_spine_to_getreq {hex(GETREQ)} 0 =>")

    # =============== access_deleted_tbl ===============
    print("# --------------- access_deleted_tbl ---------------")
    # key = { hdr.op_hdr.optype: exact; meta.is_cached: exact; }
    # actions = { get_deleted; set_and_get_deleted; reset_and_get_deleted; reset_is_deleted; }
    # default_action = reset_is_deleted();
    print("table_set_default access_deleted_tbl reset_is_deleted")
    # 若是 GETREQ & 缓存标记为已缓存 => 先读deleted寄存器, 若发现删除则不再使用缓存
    print(f"table_add access_deleted_tbl get_deleted {hex(GETREQ)} 1 =>")
    # 若是 DELREQ & 缓存标记为已缓存 => set_and_get_deleted (写 deleted_reg=1)
    print(f"table_add access_deleted_tbl set_and_get_deleted {hex(DELREQ)} 1 =>")

    # =============== access_cache_frequency_tbl ===============
    print("# --------------- access_cache_frequency_tbl ---------------")
    # key = { hdr.op_hdr.optype: exact; meta.is_cached: exact; }
    # actions = { get_cache_frequency; update_cache_frequency; reset_cache_frequency; NoAction; }
    # default_action = NoAction();
    print("table_set_default access_cache_frequency_tbl NoAction")
    # 若 GETREQ & 命中缓存 => update_cache_frequency
    print(f"table_add access_cache_frequency_tbl update_cache_frequency {hex(GETREQ)} 1 =>")
    # 若 PUTREQ & 命中缓存 (可能是更新已有缓存项) => 重置频次
    print(f"table_add access_cache_frequency_tbl reset_cache_frequency {hex(PUTREQ)} 1 =>")


if __name__ == "__main__":
    main()
