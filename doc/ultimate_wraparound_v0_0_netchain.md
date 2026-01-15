# V0-0 实验：Netchain wrap-around “快进确认（confirm）”能否快速触发 UNSAFE

目标：先不解决“从 0 推到 65535 的深前缀”，而是验证一个更直接的问题：

- 如果我们已经在临界点附近（`seq_reg == MAX`），那么 **在原始分布式语义/输入约束下**，翻转（`MAX -> 0`）是否会在很短的 suffix 内触发断言违反？

这一步的意义是：把“深前缀难题”和“翻转后是否真的会出错”拆开验证，先确认 bug 的后缀形状确实存在且可解释。

---

## 1. 输入与产物（对齐）

- Spec：`Procurator/argo/code/spec/bench/netchain_bug_s1s2.prop`
- Base Boogie（不快进）：`.tmp/dslc/netchain_bug_s1s2.tight.seq.bpl`
- V0-0 Confirm 变体（快进到 `MAX`）：`.tmp/dslc/netchain_bug_s1s2.tight.seq.confirm.bpl`
- Confirm + suffix 展开（unroll 3）：`.tmp/dslc/netchain_bug_s1s2.tight.seq.confirm.unroll3.bpl`
- Ultimate log：`.tmp/dslc/netchain_bug_s1s2.tight.seq.confirm.unroll3.gemcutter.log`
- Ultimate violation witness（GraphML）：`.tmp/dslc/netchain_bug_s1s2.tight.seq.confirm.unroll3.bpl-witness.graphml`

---

## 2. 做法（V0-0）

### 2.1 Confirm（快进）

在 `mainProcedure` 进入循环前，加入：

- `call s1_sequence_reg.write(0bv32, 65535bv16);`
- `call s2_sequence_reg.write(0bv32, 65535bv16);`

它是一个**有意的加速假设**：把系统直接放到 “临界前沿” 附近，从而避免深前缀。

实现位置：

- 变换：`dslc/transform/wraparound.py: _emit_confirm_init()`
- 入口脚本：`Procurator/argo/code/spec/prop_compile/run_wraparound.py`

### 2.2 Suffix（unroll 3）

对 `mainProcedure` 的 `while(true)` 进行 unroll，使短后缀变成 loop-free 程序，便于 Ultimate 快速出 witness。

在当前 sequential harness 的 5-phase 调度里，unroll 3 覆盖：

1) phase0：env 注入（写请求）
2) phase1：s1 ingress
3) phase2：s1 egress（会进行 assertion check）

实现位置：

- `dslc/transform/wraparound.py: unroll_mainprocedure_loop_text()`

---

## 3. 运行命令与结果

### 3.1 运行 Ultimate（GemCutter / ReachSafety-Witness）

实际运行使用：

- Toolchain：`Procurator/argo/code/spec/config/ReachSafety-Witness.xml`
- Settings：`Procurator/argo/code/spec/config/ReachSafety-32bit-GemCutter-ALL-witness.epf`
- Ultimate 超时按需设置（例如 `--core.toolchain.timeout.in.seconds=600` 或 0 禁用）

对应 log：

- `.tmp/dslc/netchain_bug_s1s2.tight.seq.confirm.unroll3.gemcutter.log`

关键结论：

- Ultimate 报告 `UNSAFE`，并写出 witness：`.tmp/dslc/netchain_bug_s1s2.tight.seq.confirm.unroll3.bpl-witness.graphml`

---

## 4. 反例形状（为什么它确实是“翻转导致的断言违反”）

### 4.1 关键语义链路（从 witness 中可见）

`confirm.unroll3` witness 里能直接看到：

1) 先把寄存器写到 `MAX`
   - `.tmp/dslc/netchain_bug_s1s2.tight.seq.confirm.unroll3.bpl-witness.graphml` 中包含：
     - `call s1_sequence_reg.write(0bv32, 65535bv16);`
     - `call s2_sequence_reg.write(0bv32, 65535bv16);`

2) s1 执行 “+1 写回” 的写路径（来自 Netchain 的 `maintain_sequence_act`）
   - witness 里包含：
     - `s1_meta.sequence_md.seq := add.bv16(s1_meta.sequence_md.seq, 1bv16);`
     - `call s1_sequence_reg.write(0bv16 ++ s1_meta.location.index, s1_meta.sequence_md.seq);`

由于 `bv16` 的模加语义，`65535 + 1 == 0 (mod 2^16)`，因此 s1 的 `sequence_reg[0]` 会从 `MAX` 翻到 `0`。

3) 断言点
   - 目前的 Boogie 变换会把所有断言折叠到单一断言点（减少 Ultimate 的 error location 数量）：
     - `call __wraparound_assert(bvule.bv16$builtin(s2_sequence_reg__dbg0, s1_sequence_reg__dbg0));`
     - `procedure {:inline 1} __wraparound_assert(cond: bool) { assert cond; }`

在 unroll 3 的短后缀里，s2 尚未完成对应的序列号更新，因此它仍保持在 `65535`，从而出现：

- `s2_seq == 65535` 且 `s1_seq == 0`，违反 `s2_seq <= s1_seq`

### 4.2 这一步的结论

V0-0 证明的是：

- “一旦达到临界前沿附近（`MAX`），在很短的 suffix 内就能进入断言违反状态”

它不证明：

- “从初态 0 一定能到达 `MAX`”（这是 V0-1 的 `closure_check`（闭包泵证明）要补齐的部分）

---

## 5. 下一步（V0-1：closure_check → confirm）

V0-1 的目标是把 “快进到 `MAX`” 从一个假设（confirm-only）变成一个有证据支撑的摘要步：

- `closure_check`：证明在选定 cutpoint/投影与输入约束下，每一轮 round 都净 `+1` 且闭包（因此 `MAX` 可达）。
- `confirm`：在全语义模型中把寄存器写到 `MAX`，并在很短 suffix 内确证翻转后缀的断言违反（输出 GraphML witness）。

可选辅助（调试/研究用）：

- `pump`：当 `closure_check` 暂时证明不了时，用“存在性 +1 闭合”的 witness 定位闭包谓词/输入约束缺口。
- `accel_probe/accel`：实验性，把“检测到泵条件后写 MAX”的快进写回编码进模型（不保证更快）。

### 5.1 推荐命令（V0-1：closure_check → confirm）

一次命令跑通证明 + 找 bug（推荐）：

```
python3 Procurator/argo/code/spec/prop_compile/run_wraparound.py \\
  --spec Procurator/argo/code/spec/bench/netchain_bug_s1s2.prop \\
  --base-bpl .tmp/dslc/netchain_bug_s1s2.tight.seq.bpl \\
  --ultimate UGemCutter-linux/Ultimate \\
  --stages closure_check,confirm \\
  --unroll confirm=3 \\
  --require-closure \\
  --ultimate-timeout-seconds 0
```

### 5.2 产物对齐（V0-1 主线）

`run_wraparound.py` 会生成并对齐这些文件名（同一个 stem）：

- 证明工件（SAFE）：
  - `.tmp/dslc/netchain_bug_s1s2.tight.seq.closure_check.bpl`
  - `.tmp/dslc/netchain_bug_s1s2.tight.seq.closure_check.gemcutter.log`
- 反例工件（UNSAFE）：
  - `.tmp/dslc/netchain_bug_s1s2.tight.seq.confirm.unroll3.bpl`
  - `.tmp/dslc/netchain_bug_s1s2.tight.seq.confirm.unroll3.gemcutter.log`
  - `.tmp/dslc/netchain_bug_s1s2.tight.seq.confirm.unroll3.bpl-witness.graphml`

### 5.3 工程化小结：缓存（让日常迭代变成秒级/分钟级）

`run_wraparound.py` 会在 **log/witness 已存在且新于输入 `.bpl`** 时自动跳过对应 stage 的 Ultimate 运行：

- 首次跑（或模型变了）仍需要 `closure_check`（~数分钟） + `confirm`（~1 分钟）。
- 后续在同一份 `.bpl` 不变的情况下，对应 stage 会直接 `[SKIP]`。
- 如需强制重跑（刷新 log/witness），加 `--rerun`。

### 5.4 （可选）先跑 pump 做诊断

当 `closure_check` 证明不了时，推荐先用 `pump` 拿 witness：

```
python3 Procurator/argo/code/spec/prop_compile/run_wraparound.py \\
  --spec Procurator/argo/code/spec/bench/netchain_bug_s1s2.prop \\
  --base-bpl .tmp/dslc/netchain_bug_s1s2.tight.seq.bpl \\
  --ultimate UGemCutter-linux/Ultimate \\
  --stages pump \\
  --ultimate-timeout-seconds 0
```

### 5.5 （可选）pump 提速：仅对 pump 使用 IcfgTransformation(Jordan)

实测 Netchain 上 `LOOP_ACCELERATION_JORDAN` 对 `pump` 有一定收益（但仍是分钟级），因此推荐只用于 pump（不影响主线 `closure_check`）：

```
python3 Procurator/argo/code/spec/prop_compile/run_wraparound.py \\
  --spec Procurator/argo/code/spec/bench/netchain_bug_s1s2.prop \\
  --base-bpl .tmp/dslc/netchain_bug_s1s2.tight.seq.bpl \\
  --ultimate UGemCutter-linux/Ultimate \\
  --stages pump \\
  --pump-toolchain Procurator/argo/code/spec/config/ReachSafety-Transformed-Witness.xml \\
  --pump-settings Procurator/argo/code/spec/config/ReachSafety-32bit-GemCutter-ALL-witness-jordan.epf \\
  --ultimate-timeout-seconds 0
```
