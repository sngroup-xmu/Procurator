#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Example script to generate table entries for the DistCache clientTrack switch.
Adjust IPs / operation codes / egress ports according to your topology and macros.
"""

# 如果有需要，可以在这里定义一些常量
PUTREQ = 0x01   # 对应 #define PUTREQ 0x0001
DELREQ = 0x02   # 对应 #define DELREQ 0x0002
WARMUPREQ_11 = 0x11  # 示例中出现过 0x11，可与 #define WARMUPREQ 0x0011 对应
WARMUPREQ_12 = 0x12  # 示例中出现过 0x12，若需要可在 P4 内部定义相应宏

def main():
    # 假设我们把 clientTrack 发往 leaf 的端口号设为 1，发往 spine 的端口号设为 2
    # 并且假设还有一个端口 3 可以通往本机或其它 host（视你的硬件/仿真环境而定）。

    # 这里的 IP 规划：
    #  - leaf 的 IP:   10.0.2.1
    #  - spine 的 IP:  10.0.3.1
    #  - client 这侧主机: 10.0.1.1 (在 ipv4_forward_tbl 中作为返回目标)

    # =============== l2l3_forward_tbl ===============
    print("# --------------- l2l3_forward_tbl ---------------")
    print("table_set_default l2l3_forward_tbl _drop")
    # 如果包要去往leaf (10.0.2.1/32)，就发出端口1
    print("table_add l2l3_forward_tbl l2l3_forward 10.0.2.1/32 => 1")
    # 如果包要去往spine (10.0.3.1/32)，就发出端口2
    print("table_add l2l3_forward_tbl l2l3_forward 10.0.3.1/32 => 2")

    # =============== hash_for_partition_tbl ===============
    # 这里匹配 op_hdr.optype，如果是PUTREQ或DELREQ，就调用hash_for_partition动作
    print("# --------------- hash_for_partition_tbl ---------------")
    print("table_set_default hash_for_partition_tbl _nop")
    print(f"table_add hash_for_partition_tbl hash_for_partition {hex(PUTREQ)} =>")
    print(f"table_add hash_for_partition_tbl hash_for_partition {hex(DELREQ)} =>")

    # =============== hash_leaf_partition_tbl ===============
    # 将计算出来的 hash 结果（meta.hashval_for_partition）用 range 进行划分
    # 如果是PUTREQ / DELREQ 都落在 0->1023，则令 egressSpec_t = 1 (发往leaf)
    print("# --------------- hash_leaf_partition_tbl ---------------")
    print("table_set_default hash_leaf_partition_tbl _nop")
    print(f"table_add hash_leaf_partition_tbl hash_leaf_partition {hex(PUTREQ)} 0->1023 => 1")
    print(f"table_add hash_leaf_partition_tbl hash_leaf_partition {hex(DELREQ)} 0->1023 => 1")

    # =============== hash_spine_partition_tbl ===============
    print("# --------------- hash_spine_partition_tbl ---------------")
    print("table_set_default hash_spine_partition_tbl _nop")
    # 如果想让 PUTREQ 走 spine，则可以取消注释：
    # print(f"table_add hash_spine_partition_tbl hash_spine_partition {hex(PUTREQ)} 0->1023 => 2")
    # 同理，如果要让 DELREQ 或其他操作也走 spine，可按需加条目

    # =============== poweroftwochoice_tbl ===============
    # 这个表通常用来比较leaf/spine的负载，然后选择更空闲的那个。
    # 这里只是示例把 0x01/0x11/0x12 指向相应动作
    print("# --------------- poweroftwochoice_tbl ---------------")
    print("table_set_default poweroftwochoice_tbl _nop")
    print("table_add poweroftwochoice_tbl poweroftwochoice 0x01 =>")  # 0x01 -> PUTREQ
    print("table_add poweroftwochoice_tbl update_leaf_load 0x11 =>")  # 0x11 -> 可能是某种 WARMUPREQ
    print("table_add poweroftwochoice_tbl update_spine_load 0x12 =>") # 0x12 -> 可能是某种 WARMUPREQ

    # =============== ipv4_forward_tbl ===============
    # 最后对于响应包（比如optype = 0x11 或 0x12），如果 dstAddr = 10.0.1.1/32，就令其出端口3
    # 这里演示 forward_normal_response 动作
    print("# --------------- ipv4_forward_tbl ---------------")
    print("table_set_default ipv4_forward_tbl _drop")
    print("table_add ipv4_forward_tbl forward_normal_response 0x11 10.0.1.1/32 => 3")
    print("table_add ipv4_forward_tbl forward_normal_response 0x12 10.0.1.1/32 => 3")

if __name__ == "__main__":
    main()
