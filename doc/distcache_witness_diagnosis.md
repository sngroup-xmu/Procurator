# DistCache：witness 诊断与“伪反例”修复记录

本文记录两个与 DistCache 相关的反例诊断：

1) `distcache_bug.prop`（Power-of-two-choice 一致性）最初出现的 **伪反例** 以及修复原因。  
2) `distcache_leaf_pktloss_clone_drop_bug.prop`（Leaf pktloss-clone 状态机）验证到的 **真实功能性 bug**，以及 witness 里对应的执行路径。

目标是把“为什么 UNSAFE”、“是不是初始化/抽象导致的伪反例”、“对应 P4 里到底哪个路径/动作”说清楚，便于后续回归测试与消融实验。

---

## 1. P2C 一致性：为什么会出现伪反例（`distcache_bug.prop`）

### 1.1 规格的直觉

`distcache_bug.prop` 想表达的性质本质上是：

> `leafload` 和 `spineload` 的大小关系，应该与 `meta.is_spine`（选择 spine/leaf）一致。

但这个性质 **只有在 P2C 逻辑真的执行** 时才有意义。

### 1.2 P4 语义根因：`meta.is_spine` 只在 `poweroftwochoice()` 里写

在 clientTrack 的 P4 中（`Procurator/argo/code/dataset/distcache/clientrackswitch/p4src/regs/load.p4`），
`meta.is_spine` 的写入只出现在 `poweroftwochoice()`：

- `poweroftwochoice_tbl` 命中 `hdr.op_hdr.optype` 后，才会执行 `poweroftwochoice` action；
- 如果 table 走了 `NoAction`（miss / default），则 `meta.is_spine` **不会被写**，它的值在验证模型里会表现为“自由/不受约束”。

因此，如果 spec 没有保证：
- 包能走到 `parse_op`（使 `hdr.op_hdr` 有意义），以及
- `poweroftwochoice_tbl` 选择了 `poweroftwochoice` action，

那么断言里对 `meta.is_spine` 的约束就会在 “P2C 根本没执行” 的路径上被检查，从而出现 **伪反例**。

### 1.3 witness 现象（旧 spec）

旧 witness 中出现了类似：
- `clientTrack_poweroftwochoice_tbl_0.hit == false`

这意味着：P2C table 没有命中（或等价地：`poweroftwochoice` action 没被执行），这时 `meta.is_spine` 未定义却被拿来和 `leafload/spineload` 做一致性检查，必然可能被“任意赋值”导致断言失败。

### 1.4 修复：把 spec 收紧到“P2C 请求路径”

我们在 `Procurator/argo/code/spec/bench/distcache_bug.prop` 中给 `clientTrack` 加了约束：

- `hdr.udp_hdr.dstPort == 5008`：使 parser 进入 `parse_op`（DistCache 保留端口）
- `hdr.op_hdr.optype == 48 (0x30)`：命中 `clienttrack_entries.txt` 中 `poweroftwochoice_tbl` 的 `poweroftwochoice` 表项

这样，性质就只在“P2C 真执行”的路径上被检查，从而消除伪反例。

> 备注：如果未来表项/解析存在不确定性，也可以在 `global assume` 里进一步加
> `clientTrack_poweroftwochoice_tbl_0.hit == true` 来把“必须执行 P2C”写得更显式（代价是对 P4B 翻译质量更敏感）。

---

## 2. Leaf pktloss-clone：真实功能性 bug（`distcache_leaf_pktloss_clone_drop_bug.prop`）

### 2.1 规格的直觉

Leaf egress 里有一个“pktloss tolerance”状态机：

- 对于 `NETCACHE_GETREQ_POP`（以及 warmup pop 等）包，会用 `clonenum_for_pktloss` 做重试，
- 代码注释描述为 “drop + clone” 循环：`drop w/ 3 -> clone w/ 2 -> ... -> drop and clone ...`

因此，在我们构造的输入场景下，期望 `leaf_drop == true`（表示 unicast 被禁用，走 drop+clone）。

### 2.2 P4 语义根因：动作缺失 `mark_to_drop`

在 `Procurator/argo/code/dataset/distcache/leafswitch/p4src/egress_mat.p4` 中：

- `update_getreq_inswitch_to_netcache_getreq_pop_clone_for_pktloss_and_getreq` 会 `mark_to_drop(standard_metadata)`；
- 但 **`forward_netcache_getreq_pop_clone_for_pktloss_and_getreq`（clonenum > 0 分支）只做了 decrement + clone，没有 `mark_to_drop`**。

这导致 “clone 发生了但 unicast 未必被禁用”，从而 `leaf_drop` 可能保持 `false`。

### 2.3 witness 如何体现（路径与违反）

在 `.tmp/dslc/distcache_leaf_pktloss_clone_drop_bug.bpl-witness.graphml` 中，可以看到：

- 进入 table：
  - `enterFunction`: `leaf_eg_port_forward_tbl_0.apply`
  - `sourcecode`: `call leaf_eg_port_forward_tbl_0.apply();`
- table 选择了 bug 动作：
  - `leaf_eg_port_forward_tbl_0.action_run := ...forward_netcache_getreq_pop_clone_for_pktloss_and_getreq;`
- 进入动作：
  - `enterFunction`: `leaf_forward_netcache_getreq_pop_clone_for_pktloss_and_getreq`
- 最终在断言点 `assert leaf_drop;` 之前的条件里包含：
  - `leaf_drop == false`

这与 P4 源码中该动作缺少 `mark_to_drop` 完全一致，因此这是 **真实功能性 bug**，不是初始化或 slicing 造成的伪反例。

---

## 3. 复现实验命令（建议）

### 3.1 Leaf pktloss-clone bug

```bash
PYTHONPATH=. .venv/bin/python Procurator/argo/code/spec/prop_compile/run_gemcutter.py \
  --spec Procurator/argo/code/spec/bench/distcache_leaf_pktloss_clone_drop_bug.prop \
  --p4b-bin P4B-Translator/build-host/p4c-translator \
  --ultimate UGemCutter-linux/Ultimate
```

输出 witness：`.tmp/dslc/distcache_leaf_pktloss_clone_drop_bug.bpl-witness.graphml`

### 3.2 DistCache P2C 一致性（伪反例修复后）

```bash
PYTHONPATH=. .venv/bin/python -m dslc.compiler \
  --backend boogie \
  --spec Procurator/argo/code/spec/bench/distcache_bug.prop \
  --out .tmp/dslc/distcache_bug.bpl \
  --p4b-bin P4B-Translator/build-host/p4c-translator \
  --work-dir .tmp/dslc/distcache_bug.work
```

若要跑 Ultimate（可能较慢，且期望不再出现“瞬间 UNSAFE”）：

```bash
UGemCutter-linux/Ultimate \
  -tc ultimate/trunk/examples/concurrent/bpl/regression/ReachSafety.xml \
  -s Procurator/argo/code/spec/config/ReachSafety-32bit-GemCutter-ALL.epf \
  -i .tmp/dslc/distcache_bug.bpl
```

