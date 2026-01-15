# V0-1 设计（Netchain）：用“闭包泵循环（closure pump）证明”支撑 `Pre(wraparound)` 加速，再用全语义快速找 bug

> 本文聚焦 Netchain（`netchain_bug_s1s2.prop`）这一类 “寄存器计数器翻转导致的 deep counterexample”：
> 从 `seq=0` 到 `seq=MAX` 需要 `2^w-1` 次有效 `+1` 写回（16-bit 时即 65535 次），即使调度是确定性的，直接展开也会卡在很长的前缀上。
>
> 核心目标：在不破坏 P4/Boogie 语义的前提下，用 **一个可证明的闭包泵循环** 证明 `MAX` 可达，从而把“几小时/不可跑”的翻转 bug 找到过程缩短到“分钟级”。

---

## 0. 状态（V0-1 已实现）

### 0.1 代码入口

- 变换：`dslc/transform/wraparound.py`
  - 新增 `WraparoundStage.CLOSURE_CHECK`（生成 loop-free 的 `closure_check` 证明任务）
- 一键脚本：`Procurator/argo/code/spec/prop_compile/run_wraparound.py`
  - 支持 `--stages closure_check,confirm`
  - 支持 `--require-closure`（`closure_check` 不是 `correct` 时拒绝跑 confirm/accel）
- Ultimate 配置：
  - `Procurator/argo/code/spec/config/ClosureCheck-ReachSafety.xml`（closure_check 用；无 WitnessPrinter）
  - `Procurator/argo/code/spec/config/ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por.epf`（closure_check 用；Hoare=None、无 per-query 超时、无 POR）

### 0.2 Netchain 实测结果（2 节点）

- `closure_check`：SAFE（`RESULT: ... correct`），`OverallTime: 400.2s`
  - log：`.tmp/dslc/netchain_bug_s1s2.tight.seq.closure_check.gemcutter.log`
- `confirm.unroll3`：UNSAFE（`RESULT: ... incorrect`），`OverallTime: 69.7s`
  - log：`.tmp/dslc/netchain_bug_s1s2.tight.seq.confirm.unroll3.gemcutter.log`
  - witness：`.tmp/dslc/netchain_bug_s1s2.tight.seq.confirm.unroll3.bpl-witness.graphml`

### 0.3 一键复现命令（推荐）

```
python3 Procurator/argo/code/spec/prop_compile/run_wraparound.py \
  --spec Procurator/argo/code/spec/bench/netchain_bug_s1s2.prop \
  --base-bpl .tmp/dslc/netchain_bug_s1s2.tight.seq.bpl \
  --ultimate ./UGemCutter-linux/Ultimate \
  --stages closure_check,confirm \
  --unroll confirm=3 \
  --require-closure \
  --ultimate-timeout-seconds 0
```

## 1. Netchain 基准与我们要证明的东西

### 1.1 基准对象

- P4：`Procurator/argo/code/dataset/Netchain/netchain_16.p4`
- 控制面：`Procurator/argo/code/dataset/Netchain/commands_1.txt`（s1）、`Procurator/argo/code/dataset/Netchain/commands_2.txt`（s2）
- Spec：`Procurator/argo/code/spec/bench/netchain_bug_s1s2.prop`
  - env 只发 `NC_WRITE_REQUEST` 到 s1（`dstAddr=167797761`），并把无关字段收紧
  - 固定 `index==0`、`hit==true`、`role`（s1=primary/s2=backup）
  - 断言：`s1_sequence_reg_0[0] >= s2_sequence_reg_0[0]`

### 1.2 我们要证明的“可达性”到底是哪种

我们不想只做“把寄存器直接设为 `MAX`（confirm 快进）”这种**假设性加速**；我们想要的是：

1) 在 spec 约束下，系统存在一个可重复执行的“写请求轮次（round）”；
2) 每执行一个 round，`sequence_reg_0[0]` 净效应为 `+1 (mod 2^w)`，且系统回到同一种“稳定形态”（可以继续下一轮）；
3) 因此，从 `0` 出发可以通过重复 round 达到 `MAX`，从而 `Pre(wraparound)` 可达；
4) 一旦到达 `MAX`，再跑 1~几步全语义即可触发翻转后缀 bug（V0-0 已验证）。

这件事本质上是一个 **闭包（closure）+ 单步效应（+1）** 的证明，而不是“跑到 65535 的 witness”。

---

## 2. 关键概念：stable cutpoint、round、closure pump

### 2.1 stable cutpoint（稳定切点）

对 Netchain（无 recirc/mirror）+ deterministic scheduler 的设置，我们可以选一个“每轮开始前”的稳定切点：

- 队列为空、mailbox 为空（没有残留 in-flight packet）
- 即将由 env 注入下一条 `NC_WRITE_REQUEST`

直觉：这时系统像一个“同步状态机”，一轮就是处理一条写请求的完整传播。

### 2.2 round（轮次）

在 `netchain_bug_s1s2.prop` 里调度是固定的（注释写的是 3 actions：env→s1→s2）。

因此我们可以把一轮定义为：

1) env 注入一个写请求包到 s1
2) s1 执行一次 pass（ingress+egress），产生下游消息
3) s2 执行一次 pass，处理下游消息

一轮结束后回到下一轮的 stable cutpoint。

### 2.3 closure pump（闭包泵循环）

我们要证明的泵循环不是“存在某个循环片段”（那容易有伪泵），而是一个 **可重复的闭包语句**：

> 对所有满足 `P` 的稳定状态 `s`，执行一轮（round）后必然得到新状态 `s'`，仍满足 `P`，并且目标寄存器槽位净效应是 `+1`。

用 Hoare triple 写就是：

- `{P(s) ∧ Stable(s)}  Round  {P(s') ∧ Stable(s') ∧ seq' = seq + 1 (mod 2^w)}`

这类性质是 **safety 形式**（assert 不会失败），因此可以被 Ultimate 当成“证明任务”来处理。

---

## 3. 为什么这个证明能把 hours 级前缀变成 minutes 级

直接求 `Pre(wraparound)` 很深，是因为需要显式走 `2^w-1` 次更新。

closure pump 的证明把问题拆成两件“深度无关”的子问题：

1) **单轮正确性（loop-free）**：一轮里目标槽位确实发生 `+1` 写回，并回到稳定切点。
2) **闭包性（仍然是 loop-free）**：一轮前后，除 `seq` 外的“稳定态投影”保持不变。

这两个子问题都可以被编码成 **一次 unroll 的断言检查**，不需要展开 65535 次。

一旦它们成立，“达到 `MAX`”就变成纯数学推理：重复 `N = MAX - seq0` 轮即可。

---

## 4. V0-1：针对 Netchain 的落地方案（用 Ultimate 做证明 + 用现有 confirm 找 bug）

### 4.1 阶段 A：构造一个“closure_check”程序（新增 stage）

新增一个 wraparound stage：`closure_check`，它生成一个 **loop-free** 的 Boogie 程序，用来证明 closure pump。

当前实现结构如下（与上面“理想化结构”一致，但避免了对所有变量的全局 `havoc`，以保持任务规模可控）：

1) **推断 1 个 round 的长度**
   - 从 Boogie 中识别 deterministic scheduler 的周期 `period`（由 `procurator_phase` 的 wrap-reset 分支推断）。

2) **unroll 成 loop-free 的 1-round 程序**
   - 对 `mainProcedure()` 的 `while(true)` 展开 `period` 次（去掉 loop）。
   - 把每个 `call main();` 进一步替换为对应 phase 分支的 body（`assume procurator_phase == k;` + phase-body），降低 CFG。

3) **符号化起点 + 写回对齐**
   - `havoc wrap_closure_seq0; assume wrap_closure_seq0 != MAX;`
   - 对参与加速的寄存器副本（例如 s1/s2 的 `sequence_reg[0]`）执行 `reg.write(idx, wrap_closure_seq0)`，保证“同起点”。

4) **snapshot + assert（闭包 + 单步效应）**
   - snapshot 投影变量 `proj(s)`（默认：`procurator_phase` 与 `*_inbox_count`/`*_egress_count` 等标量计数）。
   - round 结束后断言：
     - 投影变量保持不变（闭包）
     - 各寄存器副本都等于 `wrap_closure_seq0 + 1`（单步效应）
     - 回到 cutpoint（例如 `procurator_phase == 0`）

> 注意：这一步是“证明任务”（希望 SAFE）。它的价值在于：一旦 SAFE，就可以把 confirm 快进从“启发式”升级为“有证明支撑的加速”。

### 4.2 阶段 B：用 closure_check 的结论支撑 confirm（sound acceleration）

如果 `closure_check` 被证明 SAFE，则我们可以写清楚一条推理链：

- 初态满足 stable + spec 假设
- 每轮闭包且 `seq := seq + 1`
- 因此存在 `N` 使得 `seq == MAX`
- 所以 “在 stable 切点把寄存器设为 `MAX`” 等价于 “执行 N 轮之后的真实可达状态”

此时 `confirm` 的意义是：把 `N` 轮压缩成一步（加速），再跑短后缀找 bug（V0-0 已经验证后缀确实会 UNSAFE）。

### 4.3 阶段 C：分钟级 bug finding（维持现有 confirm.unroll3）

沿用现成：

- `confirm`：在切点把 s1/s2 的目标寄存器槽位写到 `MAX`
- `unroll3`：只跑 env→s1 的短后缀，就能让 s1 发生 `MAX->0` 并在断言点发现 `s2==MAX && s1==0`

最终产物对齐：

- proof artifact：`closure_check` 的 SAFE 日志（或 SAFE witness，如果 Ultimate 支持）
- bug artifact：`confirm.unroll3` 的 UNSAFE GraphML witness（已经有）

---

## 5. Ultimate 工具链选择（“先进工具”怎么用在这个问题上）

这个问题同时需要 “证明（SAFE）” 与 “找 bug（UNSAFE）”。两类任务对 Ultimate/solver 的要求不同：

### 5.1 closure_check（SAFE、loop-free）

由于我们把它做成 loop-free，一般不需要插值就能判定 SAFE，因此可以优先复用你们现有的 reachability toolchain：

- toolchain：`Procurator/argo/code/spec/config/ReachSafety-Witness.xml`（或 `ultimate/.../ReachSafety.xml`）
- settings：沿用 GemCutter EPF（witness 可选）

如果仍然慢/卡住，再按“更强的证明工具”逐级尝试：

1) `ultimate/trunk/examples/toolchains/Sifa.xml`（更偏符号不变式/快速抽象）
2) `ultimate/trunk/examples/toolchains/AbstractInterpretation.xml`（抽象解释给不变式线索）
3) `ultimate/trunk/examples/toolchains/InvariantSynthesisBplInline.xml`（模板不变式）
4) CHC 路线：
   - `ultimate/trunk/examples/toolchains/BoogieToChcPrinter.xml` 产出 Horn clauses
   - `ultimate/trunk/examples/toolchains/ChcSolver.xml` 或外部 CHC solver（例如 Z3 Spacer/Eldarica）尝试证明

### 5.2 confirm / pump（UNSAFE）

维持当前方案即可：

- `confirm.unroll3`：稳定分钟级出 UNSAFE
- `pump`：用于调试/定位闭包投影缺失时的证据（UNSAFE witness 很有用）

### 5.3 IcfgTransformation（可选加速器）

Ultimate 自带的 `icfgtransformation` 里有多种 loop acceleration（Jordan/QVASR/QVASRS）。

对 Netchain 的建议定位是：

- **优先用于 pump 找证据**（UNSAFE 更快）
- 如果 closure_check 仍然有 loop（没完全 loop-free），才考虑对它做加速

---

## 6. 风险点与“怎么避免伪泵/伪证明”

### 6.1 伪泵的根因

泵循环 witness 常见伪因是：

- 只在投影上闭合，隐藏状态其实在变（下一次不一定还能走写路径）
- “+1 写回”并非每轮发生（只是某个分支偶尔发生）

### 6.2 closure_check 如何避免

- **闭包是 universal**：`havoc` 让 seq 取任意值；`assert` 强制“每轮都 +1”，否则就有反例
- **净效应断言（等价于 did_inc）**：当前实现直接断言 `after == seq0 + 1`，因此不会出现“没走写回点但仍然闭包”的 vacuous 情况
- **cutpoint/投影快照**：把 `procurator_phase` 与队列 count 等标量作为投影；round 后断言它们恢复，避免靠隐藏调度/队列状态伪闭包

### 6.3 仍可能不成立的情况（这是好事）

如果 closure_check 失败，说明：

- 要么你假设的“每轮一定 +1”并不成立（比如存在阈值/模式切换/依赖 seq 的 guard）
- 要么 stable cutpoint 选错了（round 没走完系统没回到稳定态）
- 要么 spec 约束还不够（需要补充“每次都是写请求/固定 key/固定表项命中”）

这些都是模型/设计层面的真实信息，不是工具问题。

---

## 7. 对应到仓库里的具体实现改动（已实现）

> 这里记录 V0-1 为了落地 `closure_check → confirm` 实际改动了哪些文件，方便 code review，也避免把逻辑塞进 `boogie.py`。

1) `dslc/transform/wraparound.py`
   - 新增 `WraparoundStage.CLOSURE_CHECK`
   - 生成 loop-free 的 “1 个 round” 程序（`unroll_mainprocedure_loop_text(steps=period)`）
   - 关键优化：把 `call main();` 直线化为 phase-body（`_inline_deterministic_round_into_mainprocedure`）
   - 插入 `havoc wrap_closure_seq0` + `reg.write(idx, wrap_closure_seq0)` + snapshot + closure asserts
   - 断言点合并：`assert e` → `call __wraparound_assert(e)`（减少 error locations）

2) `Procurator/argo/code/spec/prop_compile/run_wraparound.py`
   - 支持 `--stages closure_check,pump,accel,accel_probe,confirm`
   - 支持 `--require-closure`：`closure_check` 不是 `correct` 时拒绝跑 confirm/accel
   - Ultimate 日志流式写入（长跑不再“无输出”）
   - stage 输出：`.tmp/dslc/<stem>.*.bpl` + `*.gemcutter.log`（confirm 默认输出 witness）

3) Ultimate 配置与调优
   - `Procurator/argo/code/spec/config/ClosureCheck-ReachSafety.xml`
   - `Procurator/argo/code/spec/config/ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por.epf`

---

## 8. 预期效果（以 Netchain 为目标的“分钟级”定义）

目标不是“从 0 展开到 196607 steps”，而是：

1) `closure_check`：分钟级内 SAFE（证明 closure pump 成立）
2) `confirm.unroll3`：分钟级内 UNSAFE（给出翻转后缀 bug witness）

这样我们在论文/报告里就能给出一个更有说服力的链条：

- “`MAX` 可达”不是拍脑袋假设，而是由 closure pump 证明支撑
- “翻转后缀确实导致断言违反”由 confirm witness 给出
