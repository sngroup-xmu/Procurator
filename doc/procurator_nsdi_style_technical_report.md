# Procurator：分布式有状态 P4 验证的实现报告（NSDI 风格技术报告）

> 本文是面向本仓库“**当前代码实现**”的技术报告：用 NSDI 论文常见的组织方式（Abstract/Introduction/Design/Implementation/Evaluation/Limitations/Related Work）把系统讲清楚，并给出我们在 Netchain 与 DistCache（寄存器翻转 / wrap-around bug）上的可复现实验结果。
>
> 读者假设：你具备基本编程语言背景，但不要求熟悉 Boogie/Ultimate。

---

## 摘要（Abstract）

我们实现了一个面向分布式有状态 P4 程序的验证原型 Procurator。系统输入为一个 DSL 规格（`.prop`），描述多交换机部署、拓扑、环境约束与 safety 断言；系统将每个 P4 节点通过 P4B 翻译为 Boogie，再生成分布式执行的 harness（pass-atomic、队列抽象、环境注入与调度），最后交由 Ultimate（GemCutter/TraceAbstraction）进行验证与反例生成。

本报告重点讨论一个“**深反例（deep counterexample）**”场景：当 bug 依赖寄存器计数器发生 **bitvector 翻转（wrap-around）** 时，从初态（寄存器为 0）到达翻转前沿可能需要接近 `2^w` 次有效更新，使得常规的反例搜索在单机上很难在可接受时间给出 witness。我们在不修改 Ultimate 内核的前提下，实现了一个 Boogie→Boogie 的“**entry_check + closure_check → confirm**”加速管线：先用 `entry_check` 排除“证明任务 vacuous（不可达导致的真）”；再用 loop-free 的 `closure_check` 证明在选定的 cutpoint/投影下，“执行一个 round”会对目标寄存器槽位产生净 `+1` 且回到同一投影类（闭包泵，closure pump）；最后在全语义模型中从临界状态附近快速确证性质违反（confirm），并通过“MAX 出发断言门控”避免翻转前的伪反例。我们在 Netchain（bv16）与 DistCache（bv32）上都能复现翻转类 UNSAFE，并产出可解释的 log + GraphML witness。

---

## 1 引言（Introduction）

**问题背景**：分布式数据面系统（例如多交换机部署的有状态 P4 程序）包含：

- 多节点并发执行（跨节点消息/转发交互）
- 数据面状态（寄存器、计数器、哈希索引等）
- 丰富的环境输入（外部报文的字段、到达端口、控制面表项）

这类系统的验证难点主要来自 **状态空间爆炸**：一方面来自并发交错，另一方面来自状态变量（尤其是 bitvector 寄存器）带来的深路径。

**我们遇到的具体瓶颈**：Netchain 中存在一个典型 bug：16-bit 序号寄存器在 `65535 -> 0` 翻转后导致跨节点关系断裂（例如 `s1_seq >= s2_seq` 被违反）。即使我们把环境输入收紧到“只发写请求、只用 index=0、角色固定”等，验证仍可能因为需要探索极深前缀而卡住数小时。

**本文贡献**（面向工程与可复现）：

1. 总结并形式化本仓库当前的 DSL→Boogie 分布式建模方式（pass-atomic + 队列抽象 + 环境注入）。
2. 实现一个不侵入 Ultimate 的 wrap-around 加速原型（Boogie-to-Boogie），并给出与代码一一对应的解释。
3. 给出 Netchain 基准上的端到端结果（时间、CFG 规模、witness 工件），以及为何它比“直接把寄存器初值设成 65535”更接近可控与可解释的工作流。

---

## 2 系统概览（System Overview）

### 2.1 输入/输出与工件

**输入**

- DSL 规格：`.prop`（节点、拓扑、环境约束、性质）
- 每个节点的 P4 程序：`*.p4` 或 `*.json`
- 控制面表项：BMv2 命令文件（例如 `commands_*.txt`）

**输出**

- Boogie 模型：`.bpl`（包含每个节点的 Boogie + 分布式 harness）
- Ultimate 日志：`*.gemcutter.log`
- GraphML witness：`*.bpl-witness.graphml`（结构化反例轨迹）

### 2.2 关键代码入口（你应从哪里读）

- 统一 CLI 入口：`./bin/procurator`（`compile/verify/wraparound/ablation/smoke`）
- DSL 编译库入口：`dslc/compiler.py`
- Boogie 后端（语义编码的核心）：`dslc/backends/boogie_backend.py` + `dslc/backends/boogie_harness.py`（入口：`dslc/backends/boogie.py`）
- wrap-around 加速变换：`dslc/transform/wraparound.py`
- wrap-around 任务生成（不跑求解器）：`dslc/workflows/wraparound.py`
- 一键跑 wrap-around 管线：`./bin/procurator wraparound`（实现：`dslc/cli/wraparound.py`）

---

### 2.3 术语：Harness 是什么？（用一句话说清楚）

在验证里，**harness** 指“为了验证而生成/手写的**驱动程序（driver/testbench）**”：它不实现 P4 程序本身的功能，而是负责：

- 建模环境输入（外部报文如何产生、字段如何 nondet/havoc、哪些约束必须满足）
- 建模系统结构（拓扑/转发/入队/队列容量等）
- 建模并发/调度（下一步执行 env 注入还是某个节点的一次 pass）
- 在合适位置插入断言（assert）来表达我们要验证的性质

在本仓库里，“被验证的程序本体”主要是 **P4B 输出的每个节点 Boogie**（例如 `s1_mainProcedure()` 表示 s1 的一次 pipeline pass），而 harness 由 `dslc/backends/boogie_harness.py` 生成、并由 `dslc/backends/boogie_backend.py` 拼接进最终 `.bpl`；典型入口是：

- `procedure ULTIMATE.start()`（Ultimate 的入口，负责启动主循环）
- `procedure mainProcedure()`（一次性初始化 + `while(true)`）
- `procedure main()`（每步只执行一个动作：env 注入/节点 pass/host 行为/idle）
- `procedure s1__enqueue_s2()`（跨节点转发：只复制 `hdr.*`，不复制 `meta.*`）

用“接近代码的伪代码”表示，sequential harness 大致长这样（仅示意）：

```
procedure ULTIMATE.start() { call mainProcedure(); }

procedure mainProcedure() {
  init queues, regs, dsl state;
  while (true) {
    call main();          // one scheduler step
    procurator_step++;
  }
}

procedure main() {
  choose one action:
    env_inject(s1) | node_pass(s1) | node_pass(s2) | ...
}
```

这就是你在 `.bpl` 里看到的“很多与 P4 无关的东西”的来源：它们属于 harness，目的是把“多节点系统语义”编码成单个可验证程序。

---

## 3 设计：分布式语义如何落到 Boogie（Design）

本仓库的核心设计原则是：**把复杂系统的并发点压缩到“pass/step 的边界”**，让验证器主要面对“调度选择（哪个 actor 在下一步执行）”，而不是在每条语句之间交错。

### 3.1 执行语义：pass-atomic / step-atomic

我们把系统的一步定义为：

- **环境注入**：产生一个外部输入报文（受 `.prop` 的 assume/env 收紧）
- **节点执行**：某个节点处理一个输入（完整 ingress/egress 或拆成 two-stage）
- **host 行为**：可选的 host send/recv（用于更贴近 Promela 的交互）

#### 3.1.1 Sequential harness：单线程调度器（推荐做证明/加速）

在 Boogie 的 sequential harness 中，这种“一步一个动作”的语义直接编码为：

- `procedure main()`：一次只执行一个动作（nondet 或 deterministic round-robin）
- `procedure mainProcedure()`：一次性初始化后 `while(true) { call main(); step++; }`

其中 `global.deterministic_scheduler=true` 的 deterministic round-robin 为了避免“某一轮 action 暂时不可执行”导致系统死锁（例如 host inbox 为空时的 `host_recv`），会把每个 action 包在 `if (enabled) { ... }` 中：当 `enabled` 不满足时该步为 no-op（idle），调度仍继续推进到下一 phase。

对应实现：

- `dslc/backends/boogie_harness.py:_emit_sequential_main`（生成 `main()` 与 action 列表）
- `dslc/backends/boogie_harness.py:_emit_sequential_main`（生成 `mainProcedure()` 的 while(true) 驱动）

> 这套 sequential harness 的目的，是让 Ultimate 可以在一个“经典的顺序程序 + while(true)”框架下做 unbounded 推理；并发 harness（fork/atomic + 全局锁）也存在。  
> 对 wrap-around 加速而言：`entry_check/closure_check` 需要 sequential harness（便于把 “round” 写成固定相位并做 loop-free 证明）；但 `confirm` 已支持切到 concurrent harness：在 `ULTIMATE.start()` 中 fast-forward 目标寄存器到 `MAX`，然后让 GemCutter 在 fork 模型里寻找翻转后缀反例。

#### 3.1.2 Concurrent harness：fork 多线程 + atomic + 全局锁（可验证，但更难讲清楚/更易踩坑）

我们也支持一个更“长得像并发程序”的 harness：把每个 actor 编成一个线程，并在 `ULTIMATE.start()` 中 `fork` 出来：

- `EnvThread()`：环境注入线程
- `<node>Thread()`：每个交换机节点一个线程
- `<host>Thread()`：每个 host 一个线程（可选）

其核心形状（伪代码）是：

```
procedure ULTIMATE.start() {
  init_globals();
  fork 0 EnvThread();
  fork 1 s1Thread();
  fork 2 s2Thread();
  ...
}

procedure s1Thread() {
  while (true) {
    if (*) {
      atomic { assume procurator_lock == 0; assume s1_inbox_count > 0; procurator_lock := 1; }
      // one pass / one stage
      ...
      atomic { procurator_lock := 0; }
    }
  }
}
```

对应实现：

- 线程生成：`dslc/backends/boogie_harness.py:_emit_env_thread/_emit_node_thread/_emit_host_thread`
- fork 入口：`dslc/backends/boogie_harness.py:_emit_ultimate_start`

**为什么还要全局锁？**

因为我们希望实现“pass-atomic”的建模初衷：并发交错点只发生在“选哪个 actor 执行下一步”，而不是在 P4 程序的每条语句之间交错。全局锁把每次节点的 pass（或 two-stage 的 ingress/egress stage）线性化，等价于把并发语义压缩成“调度选择”的 nondet。

> 重要现实：在 concurrent harness 下，如果某些线程（尤其是 host send/env inject）在锁外写了节点的 mailbox 变量，就可能在一个 pass 中间覆盖报文字段（单槽 mailbox 抽象会放大这个问题）。因此 concurrent harness 更适合“只建模 env 注入 + 节点 pass”，并把 host 建模留给 sequential harness，或者给 host 也引入同一把锁/快照语义。

#### 3.1.3 在 fork 多线程模型下能“证明”吗？需要哪些前置条件？

可以，但要区分两个层次的“证明”：

1) **相对我们模型（harness + 抽象）的证明**：工具证明的是“在这份 Boogie 模型的语义下”，性质是否对所有执行成立。
2) **相对真实系统的证明**：这还要求我们的抽象（Bag(K)、单槽 mailbox、pass-atomic、表项抽象）是健全/适用的——这属于建模假设，需要在论文里作为能力边界写清楚。

在第 (1) 层次上，Ultimate 对 Boogie 并发的支持关键在于：`fork` 不是所有后端都支持。实践上：

- **GemCutter**：面向并发程序的验证器；支持 Boogie/C 的 fork 并发，并使用 *sound sequentialization* 把并发验证规约到顺序验证（同时利用可交换性/CEGAR 缩减交错）[14]。
- **Automizer/TraceAbstraction（顺序）**：更适合我们当前的 sequential harness；它们不一定支持带 `fork` 的 Boogie 输入。

因此，如果你坚持“fork 一堆线程”的模型并希望工具给出 `SAFE` 结论，基本前置条件是：

- **语言/工具链前置条件**
  - Boogie 程序在 Ultimate 的 Boogie 方言下可解析（`fork <id> proc();`、`atomic { ... }`、位向量内建等）。
  - 所有 `procedure` 的 `modifies` 列表必须覆盖真实副作用（包括被 `fork` 出来的线程可能写的变量）；否则 Ultimate 会在 typecheck 阶段直接失败（我们已把这些规则固化在 harness 生成里）。
- **建模前置条件（决定 UNSAFE 是否会伪）**
  - 单槽 mailbox 抽象要求：一个 pass/stage 期间“当前处理的报文字段”不应被其他线程覆盖；否则会出现“半包混合”的伪轨迹。我们在 two-stage 节点上用 mailbox snapshot/restore 解决了 ingress/egress 分裂导致的混合；但如果 host/env 在锁外写 mailbox，仍可能造成更强的混合（需要额外约束或同一把锁）。
  - `assume` 必须表达我们认可的环境（例如 DistCache 的 power-of-two-choice 属性必须确保相关表项路径确实被执行，否则容易因 `meta` 未赋值而出现伪反例——这类问题应该通过 spec 收紧修复，而不是靠后端“猜测”）。

在这些前置条件满足时：

- GemCutter 若输出 `UNSAFE`，witness 对应一个具体 interleaving（调度 + 输入），这是对模型的 **sound** 反例；
- 若输出 `SAFE`，则是在模型语义下对所有 interleavings 的证明（依赖其 sequentialization/CEGAR 的健全性）[14]；
- 若输出 `UNKNOWN`，通常意味着抽象/不变式不足或搜索不收敛（并不否定性质，也不否定 bug）。

最后一个很实用的工程结论是：**在我们采用“全局锁 + pass-atomic”的前提下，concurrent harness 与 sequential harness 本质上只是两种编码**（都在表达“下一步 nondet 选一个 actor 执行一次原子 step”）。因此：

- 如果你的目标是“更容易证明/更容易做加速/更容易解释”，优先选 sequential harness；
- 如果你的目标是“与并发验证器接口对齐/保留 fork 形状/尝试利用 GemCutter 的并发能力”，再选 concurrent harness，并严格管住 mailbox 的原子性（否则最容易产生伪轨迹）。

从“witness 合法性”的角度看，这句话还有一个推论：**只要你的并发模型确实被这把全局锁线性化（每次 pass/stage 都在锁保护下完成），那么 sequential harness 上得到的任意一条执行轨迹，都可以被理解为 fork 模型中的一个合法 interleaving**——只要让对应线程按顺序拿到锁，其他线程在中间保持不运行即可。因此：

- sequential 上找到的 `UNSAFE` 反例，是 fork 模型的一个合法反例（存在性意义下的 soundness）；
- 反过来不一定：fork 模型里允许更多交错，sequential 只是其中一种调度实现。

### 3.2 队列抽象：Bag(K) + mailbox

跨节点交互通过“入队到下游节点 inbox”建模。当前默认抽象是：

- 每个节点有 `*_inbox_count`（整数计数，容量上界 K）
- 报文内容通过一组全局变量表示（单槽 mailbox）；入队时将 `hdr.*` 从 src 复制到 dst（不复制 `meta.*`）

其效果是一个 **Bag(K)**（不保序）抽象：只关心“有多少条消息”，不关心 FIFO 顺序。这大幅降低状态空间，并与后续 commutativity/POR 优化兼容。

### 3.3 环境收紧：用 `.prop` 控制输入空间

对于深 bug，环境收紧是必要条件。以 Netchain 为例，我们在 `.prop` 中固定：

- 报文字段（协议栈 valid、op、key、overlay terminator 等）
- 控制面命中（`find_index.hit` 等）
- 角色（role=100/101）
- 关键 index（location.index=0）

对应 spec：`Procurator/argo/code/spec/bench/netchain_bug_s1s2.prop`

### 3.4 P4 状态初始化：寄存器默认值

P4 语义里寄存器如果没有由控制面显式配置，通常默认 0。Boogie harness 在初始化时对寄存器数组加入：

- `assume (forall i :: reg[i] == 0)`
- 同时保留 `reg[0]==0` 作为辅助（便于某些工具/简化）

对应实现：`dslc/backends/boogie_harness.py:_emit_register_init_assumes`

---

## 4 设计：为什么 wrap-around 让验证变慢（Motivation）

假设一个 w-bit 寄存器 `R[idx]` 每次有效写回执行 `R[idx] := R[idx] + 1 (mod 2^w)`。

要观察到翻转 `MAX -> 0`，至少需要到达 `R[idx]==MAX` 的状态；从 0 推到 MAX 在最坏情况下需要 `2^w - 1` 次有效更新。对于 `w=16`：

- 需要 65535 次有效更新
- 在分布式模型中，每次有效更新还需要若干调度步（env→s1→s2...），反例前缀深度进一步放大

这解释了你观察到的现象：

- 直接从初态跑：工具需要探索“很深的未来”，可能数小时没有 witness
- 人为把寄存器初值设成 65535：立即落在临界点附近，短 suffix 就能触发 bug

但后者的问题是：它把问题变成“从一个不可证明可达的状态出发”，会带来 **语义与实验意义** 的争议。因此我们希望一个更可解释的流程：既能快，也能说明“为什么这个临界状态是合理的目标”。

---

## 5 设计：wrap-around 加速管线（closure_check → confirm）（Design）

我们的核心思路不是直接求 `Pre(Bad)`，也不是展开 `2^w` 次更新，而是先证明一个更“结构化”的事实：

> 在选定的 cutpoint/投影下，存在一个闭包的 round 摘要：每执行一个 round，目标寄存器槽位净效应为 `+1`，并回到同一投影类（closure pump）。

这件事可以被编码成一个 **loop-free 的 SAFETY 证明任务（`closure_check`）**。当该证明成立时，我们就有了“从 0 可以推进到 `MAX`”的可解释支撑，于是可以做两段式：

1. **closure_check（证明阶段）**：证明 round 的闭包 + `+1` 净效应（避免伪泵导致的伪可达性）
2. **confirm（确证阶段）**：在全语义模型里把状态快进到临界状态附近，验证翻转后缀是否真的会触发断言违反

当 `closure_check` 暂时证明不了时，我们仍保留一个 **可选的 pump（witness 阶段）** 用于诊断/CEGAR（先找“存在泵循环”的反例轨迹，再决定把哪些状态量纳入闭包谓词）。

### 5.1 关键概念：投影（projection）与 cutpoint

如果我们希望一个循环可以“被泵”（重复执行很多次），必须确保循环前后某些状态等价。我们用一个投影 `proj(s)` 表示“我们要求保持不变的那部分状态”。

在 v0/v1 原型中：

- 默认投影包含 `procurator_phase`（调度相位）和所有 `*_inbox_count`/`*_egress_count`（队列计数）
- 只投影 **标量**（不投影数组/结构体），以便快照为 local 变量

同时，我们只在某些“**cutpoint**”位置比较投影，避免在任意语句点比较：

- 默认 cutpoint 条件：`procurator_phase == 0`
- 直观含义：只在“调度回到 round-robin 的边界”处对齐状态

### 5.1.1 closure pump（闭包泵）到底是什么：一个可证明可重复的 `+1` round 摘要

为了让概念更直观，我们先抛开 Boogie，用最小数学语言定义我们真正想要证明的东西：

- 设 **一轮 round** 的语义是 `Round(s) -> s'`（在我们的 sequential harness 里，round 就是把调度相位从 `0..period-1` 跑一遍）
- 设目标寄存器槽位是 `R[idx]`，位宽是 `w`（例如 `w=16`，则 `MAX=2^w-1=65535`）
- 我们选择一个投影函数 `proj(s)`（例如只保留 `procurator_phase` 与 `*_inbox_count`）

我们说“存在一个闭包泵（closure pump）”，是指在 cutpoint 上，round 的行为满足一个 **闭包 + 单步效应** 的 Hoare 形式：

- **闭包（closure）**：`proj(s') == proj(s)`（round 前后回到同一投影类，下一轮还能“以同样方式”继续）  
- **单步效应（+1）**：`R[idx](s') == R[idx](s) + 1 (mod 2^w)`（目标槽位净效应为 +1）

直觉：只要闭包泵成立，那么每执行一轮，`R[idx]` 就 +1 一次，于是你可以把寄存器从 0 推到 `MAX`，再下一轮触发 `MAX -> 0` 的翻转。

> 对比：**pump witness**（我们仍保留）通常是一个“存在性证据”：它会找出一条轨迹，展示“某次回到同一投影类时净效应为 +1”。但仅靠存在性，可能出现伪泵（隐藏状态变化导致无法长期重复）。这也是我们引入 `closure_check` 的原因：把“可重复性”变成一个能被 Ultimate 证明的 SAFETY 任务。

### 5.1.2 为什么“一次能增 1”不代表能增 1e9 次？

你提出的直觉“能增一次就能增很多次”只有在一个前提下成立：**下一次增 1 的前置条件（guard）可以被再次满足**，并且系统不会因为这次增 1 而进入“再也增不了”的区域。

现实里经常不成立，原因通常是“增 1 伴随着其他状态变化”，这些变化会截断后续增量。给几个极简例子（用 P4/状态机直觉理解即可）：

**例 1：消耗型资源（能增一次但不能重复）**

- 有两个寄存器：`credit_reg` 和 `seq_reg`
- 每次写请求会做：
  - `if (credit_reg[0] > 0) { seq_reg[0]++; credit_reg[0]--; }`

若 `credit_reg[0]` 初始为 1，则确实“能增一次”，但第二次 guard 失败，无法继续增。

**例 2：阈值截断（只允许增到某个上限）**

- `if (seq_reg[0] < 100) seq_reg[0]++; else mark_to_drop();`

这种程序里不存在 wrap-around（增不到 MAX），因此 “从 MAX 出发能触发的 bug” 很可能是不可达的伪 bug。

**例 3：角色/模式切换（第一次之后走不同分支）**

- 第一次写请求会触发 failover，导致 `role_reg` 改变
- 后续只有 leader 才会 `seq_reg++`

则“能增一次”并不能推出“能增很多次”，因为系统模式已经改变。

所以你直觉里说的“除非做了某些限制”是对的：这个“限制”就是系统必须存在一个可重复执行的循环结构，而这正是我们引入 **闭包泵（closure pump）/`closure_check`** 的原因——它要捕捉的不是“增一次”，而是“**每一轮都能回到同一类状态并净 +1**”。

### 5.2 closure_check：把“闭包泵”改写为一个 loop-free 的 SAFETY 证明任务

在 `closure_check` 阶段，我们不去“找 witness”，而是让 Ultimate 证明一个 round 摘要对所有可能执行都成立。具体做法（Boogie→Boogie 变换）：

1. 自动推断 sequential scheduler 的周期 `period`（寻找 `if (procurator_phase == period-1) { procurator_phase := 0; }` 形态）。
2. 将 `mainProcedure()` 的 `while(true)` 展开 `period` 次，使程序 loop-free（只包含 1 个 round）。
3. 为降低 CFG 规模，把每个 `call main();` 替换为对应相位分支的 body（并加 `assume procurator_phase == k;`），得到“直线化的 round”。
4. 在 round 开始前插入：
   - `havoc wrap_closure_seq0; assume wrap_closure_seq0 != MAX;`
   - 对参与加速的寄存器副本（例如 s1/s2 的 `sequence_reg`）执行 `reg.write(idx, wrap_closure_seq0)`，保证它们从同一序号出发。
   - 快照投影变量 `proj(s)`（默认：`procurator_phase` 与各队列 count）。
5. round 结束后断言：
   - 投影变量未变（闭包）
   - 各寄存器副本都等于 `wrap_closure_seq0 + 1`（单步效应）
   - 回到 cutpoint（例如 `procurator_phase == 0`）

对应实现：`dslc/transform/wraparound.py` 中 `WraparoundStage.CLOSURE_CHECK` 分支（`unroll_mainprocedure_loop_text` / `_inline_deterministic_round_into_mainprocedure` / `_emit_closure_setup` / `_emit_closure_asserts`）。

> `closure_check` 的结果如果是 `correct`，我们就可以把 confirm 的 “写到 MAX” 解释为一个摘要步（否则 confirm 只能作为条件反例）。

### 5.3 pump（可选）：把“存在泵循环”改写为 reachability

在 pump 阶段，我们对 `mainProcedure()` 的 while-loop 做插桩，把每一步变成：

1. 读寄存器旧值
2. `call main();` 执行一步
3. 读寄存器新值
4. 若到达 cutpoint：
   - 第一次到 cutpoint：记录快照（投影变量 + 寄存器值）
   - 之后每次到 cutpoint：检查
     - 投影是否与快照一致
     - 寄存器新值是否等于快照值 `+1`
     - 若成立，触发 `assert false`（这是“泵循环存在”的 witness）

对应实现：`dslc/transform/wraparound.py:_emit_step_block` + `_emit_pump_error_proc`

> 注意：pump 阶段会剥离原本的 DSL 断言与 `__dbg` 快照赋值（这些不是 P4 语义的一部分，只是性质检查/可读性 instrumentation），以减少 CEGAR 目标与公式规模。对应实现：`_strip_other_asserts_for_pump` 与 `_strip_debug_snapshot_for_pump`。

### 5.3.1 为什么“找到 pump/closure pump”就能“跳到 65535”？

这里的核心是一条非常朴素的“加法推理”：

- 如果你有一个可重复使用的片段，每次净效应是 `R[idx] := R[idx] + 1 (mod 2^w)`
- 那么重复 `k` 次，净效应就是 `R[idx] := R[idx] + k (mod 2^w)`

对 Netchain 的序号寄存器，`w=16`，所以 `MAX = 65535`：

- 若某次 cutpoint 时 `R[idx]=0`，重复 65535 次后 `R[idx]=65535`
- 再下一次 `+1` 就发生翻转：`65535 + 1 (mod 2^16) = 0`

因此，“pump → 到 MAX → 翻转”在逻辑上是连起来的：**pump 是证明“可以持续推进”的结构证据**，而 `MAX` 是翻转前沿的临界点。

### 5.3.2 32 位寄存器也适用吗？

概念上完全适用：如果 `w=32`，同样有 `MAX = 2^32-1 = 4294967295`。只要你能找到一个真正可重复的 `+1 pump`，就能把寄存器推到 `MAX` 并触发翻转。

但工程上有一个巨大差异：从 0 到 `2^32-1` 需要约 43 亿次有效更新，任何“按步展开/显式跑前缀”的方法都会崩溃。因此 32 位场景必须依赖 **加速/摘要（acceleration/summarization）**：不要真的循环 43 亿次，而是把循环的净效应一次写出来（例如把 `R[idx]` 直接写到 `MAX`，或写成 `R[idx] := R[idx] + k` 的形式）。

### 5.3.3 我们怎么判断当前 pump “够不够真”？（为什么要谈“证明味”）

这里的“证明味”，不是说我们现在就要做完备证明，而是指：**我们希望减少“从不可达状态出发的伪反例”**，让加速得到的 bug 更可信、更可解释。

关键点是：当前 pump 的闭合条件是 `proj(s')==proj(s)`，它是一个抽象等价类。抽象越粗，越容易出现：

- 抽象上看起来“回到了同一状态”（投影相等）
- 但具体状态已经变了（例如某个隐藏寄存器/模式位变了），导致这个片段其实无法重复执行很多次

因此，“找到一次 pump”并不自动推出“能泵到 MAX”。我们建议把 pump 视为一个 **可迭代加强的证据**：

1) **证据等级 0（confirm-only）**：从 `MAX` 出发能触发真实断言 ⇒ “条件反例”（if MAX reachable）
2) **证据等级 1（当前 pump）**：存在一段 `proj` 闭合且净 `+1` 的片段 ⇒ “MAX 可能可达”的结构证据
3) **证据等级 2（repeatability check）**：证明该片段至少能连续重复 2 次/3 次（存在 witness） ⇒ 大幅降低“伪泵”概率
4) **证据等级 3（投影 CEGAR）**：若重复失败，则把导致失败的关键状态量加入 `proj`，再次寻找泵 ⇒ 逐步逼近“真正可重复”的循环

其中 (2) 的“重复检查”是最便宜也最实用的工程手段：把 witness 里推断的 loop 片段尝试再跑一遍（相当于在模型里要求出现两次相同类型的 `+1` 闭合）。如果连重复 2 次都做不到，那它几乎肯定不是能泵到 `MAX` 的循环。

> 结论：所谓“证明味”有意义，是因为它决定了我们把 `confirm` 的结果解释成“真实 bug”还是“可能的伪 bug”。对于 Netchain 这种我们已强力收紧环境且写路径稳定的程序，当前做法作为 bug-finding 加速是合理的；但对一般程序，必须配合 repeatability/投影 CEGAR 才能避免被“能增一次但不能长期增”的程序形态误导。

### 5.3.4 你想要的“sound”：需要证明什么，才能说“不会中途停掉”？

你提到的“sound”，如果我们把它严格化，通常至少要补上下面这个缺口：

> `confirm` 阶段从 `R[idx]=MAX` 出发找到的 bug，是否一定能从初态触发？

要把它变成“从初态可达”的结论，必须证明一个 **可达性前提**：`R[idx]=MAX` 的状态（或翻转前沿）在原模型里是可达的。

你提出的“不会被别的指令截断”本质上是在问：**能否证明一个“自增过程”在足够长的时间里一直保持可用（不会因为其他状态变化导致 guard 失败/写回点消失）？**

这件事通常需要证明一个“闭包（closure）/可重复性（repeatability）”性质。直观上它和形式化验证里非常常见的 **lasso/ultimately-periodic** 结构是同一类思想：LTL/ω-正则模型检测中的反例通常可表示为“前缀 + 循环”，循环段可被重复（pump）[1,2,3]；而在程序分析/终止性里也会专门用“lasso programs（stem+loop）”来刻画可重复的循环片段 [4]。我们这里把循环段的语义换成了“在 cutpoint 上闭合，并对目标寄存器净 `+1`”，因此需要一个更强的“闭包证明”来避免伪泵。

形式化地说，我们希望存在一个状态谓词 `P(s)`（把它理解成“增 1 循环的前置条件”），满足：

1) **可达性**：存在某个 reachable 状态满足 `P(s)`（从初态能走到进入稳定自增模式的状态）
2) **闭包（关键）**：从任意满足 `P(s)` 的状态，执行一次“一个周期”（例如 round-robin 的一圈）后还能回到 `P(s')`
3) **净效应**：在这个周期内，`R[idx]` 的净效应就是 `+1 (mod 2^w)`，并且没有别的写把它改成别的值

如果 (1)(2)(3) 都成立，那么你就能用归纳法得到：

- 对任意 `k>=0`，存在一条执行可以重复该周期 `k` 次
- 因此从 `R[idx]=0` 出发，取 `k = 2^w-1` 就能到达 `R[idx]=MAX`

这就是你想要的“不会中途停掉”的证明形态：它不靠展开 2^32 次，而靠 **闭包 + 归纳**。这与非终止证明里常用的 **(closed) recurrent set**（可达 + 对转移闭包）非常接近，并且很多工作会把它改写为 safety 来求解 [8,9,10]。从“循环加速/摘要”角度看，我们最终想要的是把“执行 k 次循环/round”的净效应写成一个摘要（acceleration / transitive closure），避免显式展开超深前缀 [5,6,7,11]。

> 重要区分：这依然是“存在性”的 sound（存在一条可泵到 MAX 的执行），而不是“对所有环境输入都必然自增到 MAX”。后者是更强的 liveness/策略问题，需要更强假设（比如环境持续发写请求、调度公平等），不一定是我们想要/能要的结论。

**我们当前做法处在什么位置？**

- `confirm`：验证了 (3) 的“后半段”（从 MAX 附近确实能触发真实断言违反），但没有证明 (1)(2)
- `pump`：提供了一个“(2)(3) 的弱证据”（在投影意义下闭包且净 +1），但不是严格的闭包证明

因此，严格来说：**当前做法是 bug-finding 加速（conditional counterexample + 结构证据），不是一个完备的可达性证明链**。

**要把它升级到更 sound，我们应该怎么做？（路线图）**

最实用的两步是：

1) **repeatability check（存在性加强）**：要求 witness 中的泵循环能连续出现 2 次/3 次（把伪泵概率快速压下去）
2) **closure check（进入证明链）**：在 cutpoint 处快照一组“影响 guard/写回的持久状态变量”，跑一个周期后断言这些变量恢复原值（或满足同一谓词 `P`）。失败就用反例把缺失变量加入 `P`（CEGAR）

当 closure check 成功后，我们就有资格把 “快进到 MAX” 解释成一个 **可证明正确的摘要步（summary/acceleration step）**，并把 confirm 的 bug 结论提升为“从初态可达的真实 bug”。

### 5.3.5 并发版本的 pump 需要什么理论支撑？（回答“fork 一堆线程也能泵吗？”）

把“并发/干扰”先翻译成 **P4/交换机** 能对齐的语义（而不是 CPU 线程）：

- 我们的一步（step）= 一次 **处理一个包** 的 pass（或启用 two-stage 时的一次 ingress/egress stage）。
- “泵片段（pump segment）”= 你希望反复重复的一段行为，例如某类包触发 `R[idx] := R[idx] + 1`。
- “插入干扰（interference）”= 在两次泵片段之间，系统先处理了 **别的包/事件**（可能在同一节点，也可能是别的节点的一次 pass）。

你说“交换机之间不共享变量，只有消息传递”，这在分布式层面是对的；但干扰仍然会出现，因为：

1) **同一交换机内**仍有跨包共享状态（寄存器/计数器/状态机变量）；  
2) **消息顺序/队列状态**本身就是全局状态：插入一个包，会改变“谁先看到什么”。

一个最贴近 P4 的“干扰”例子，就是你论文里提到的 **recirculation fan-out 非原子广播**：

- 交换机 T 要把每个写请求发给两个副本服务器 `S1,S2`。实现方式是：第一轮 pass 发出第 1 份，然后 `recirculate()` 让同一个包再跑一轮 pass 发第 2 份。
- 两个写请求 A,B 紧挨到达时，合法的发送序列可能是：`A, B, A', B'`（A' 是 A 的 recirc copy，B' 同理）。
- 此时 `S1` 看到的顺序是 `A → B`（A 和 B'），而 `S2` 看到的是 `B → A`（B 和 A'），从而违反“副本顺序一致性”。  
  这就是“插入干扰”的含义：**B 的处理被插在 A 的两次发送之间**。注意这完全不需要跨节点共享寄存器，纯消息交错就能触发功能性错误。

再给一个“为什么泵会中断”的例子（和 Netchain/DistCache 更接近）：

- 真实自增通常带 guard：`if (role==MASTER && op==WRITE && hit(table)) { R[idx]++; }`
- 干扰包（failover/timer/recovery）可能把 `role_reg` 改成 BACKUP 或让命中条件变 miss。结果是：第一次 `WRITE` 能自增，但后面自增被截断——这就是“伪泵”的典型来源。

有了这些例子，再回到“并发 pump”的两种目标强度就清晰了：

**A. 存在某个调度可以一直泵（existential schedule pump）**  
目标是“找 bug（UNSAFE）”：只要存在一条执行能把寄存器推到翻转前沿并触发错误就够了。  
在我们的 pass-atomic 语义下，“fork 一堆线程”本质只是“下一步 nondet 选哪个 actor 跑一次原子 pass”，因此这类 pump 最容易落地（也是 V0/V1 的主线）。

**B. 对干扰鲁棒的泵（interference-robust pump）**  
目标是“不会被其它包/事件打断”。工程上你必须证明一件很具体的事：  
**哪些插入的包/事件与这次 `R[idx]++` 无关（或可交换），因此不会改变净效应？**  
这就是 POR/DPOR 背后的 commutativity/independence 直觉；GemCutter 的 sequentialization 也依赖类似思想来减少交错 [14]。

对我们当前系统（务实版）：V0/V1 以 A 为主（让 UNSAFE 更快、witness 可审计）。如果要升级到 B，下一步应利用 P4B 的 state R/W（细化到 object×index）把“影响目标槽位/guard 的事件集合”做成可证明的闭包条件，再用 closure_check 反例做 CEGAR 精化。

**并发下为什么“pump 可行，但 closure_check 直接搬过去会变味”？**  
这是因为两者在验证逻辑上一个是“找存在”（UNSAFE/可达性），一个是“证成立”（SAFE/全称）：

- `pump`：我们把“存在一个 +1 闭合循环”编码成 `assert false` 可达性问题。只要 **存在** 某条调度/输入能走到错误点，工具就会给 witness。  
- `closure_check`：我们想证明的是一个“摘要步”对所有执行都成立（从任意 `wrap_closure_seq0 != MAX` 出发，跑完一个 round 后一定净 +1 且投影恢复）。这本质上是 **对 round 内所有 nondet 选择的全称性质**。

在 fork 并发 harness 里，round 内最大的 nondet 就是“下一步哪个线程拿到锁”。如果你不固定它，`closure_check` 会变成在问：  
**“不管怎么调度（甚至 env 多注入几次/节点多跑几次），只要跑完一段你定义的‘round’，就一定净 +1 并回到投影类吗？”**  
这已经接近 B（鲁棒）而不是 A（存在性）了，所以往往证明不了，也不符合我们 V0/V1 的目标。

因此 V0/V1 的工程策略是：把 schedule 明确化（sequential harness 的 `procurator_phase`），把“round”定义成一个固定的顺序列表，然后对这个固定 round 做 `closure_check`。这等价于：**我们选择了一条调度 A，并证明在该调度的一个周期下确实是闭包 +1**。  

更关键的是：这不会让后续的“并发找 bug”变得不 sound。原因很简单：在我们采用 pass-atomic（全局锁）时，fork harness 里的并发语义本质也是“每一步 nondet 选一个 actor 跑一次原子 pass”，因此它**包含所有顺序调度作为特例**。所以只要我们用 `entry_check + closure_check` 证明“按调度 A 可以推进到临界前沿”，那么“临界状态附近（例如 `MAX`）”在并发模型里同样是可达的；接下来再用 **并发 harness 的 confirm** 去探索翻转后的交错，就能得到对并发 bug 也合理的 witness。

若你坚持在 fork harness 上做同样的事，本质上也需要引入类似的 phase 变量/调度契约（否则 round 无法无歧义定义）。

> 这里常见的误解是把“公平性（fairness，不饿死）”当作 closure_check 的关键。公平性是一个 **liveness 假设**（“最终会发生”），它并不能自动给你一个“固定长度的 round”，也不能阻止 round 内被插入额外的 env 注入/额外的节点 pass。要让 closure_check 回到我们想要的“loop-free 摘要证明”，最直接的方法仍然是：把调度在模型里写死（phase/round-robin），而不是事后用公平性去约束所有可能的并发交错。

进一步说：**sequential harness 的 closure_check 并不是在宣称“真实系统会按这个顺序跑完一轮”**。它只是把“调度”当作反例/证据的一部分：我们选定一个具体顺序（round-robin），然后证明“如果按这个顺序重复执行，并且输入满足 `.prop` 约束，那么寄存器每轮净 +1 且回到同一投影类”。这足以推出 **存在一条执行** 能到达 `MAX-1`（从而支撑 fast-forward 的合理性）；但它不等价于“所有公平调度下都必然到达 `MAX-1`”。后者是 liveness（甚至是策略/对抗环境）问题，超出 V0/V1 的目标。

**为什么“已经有 A 了”还要考虑 B？（你提出的疑问）**  
如果你的目标只是 **找 bug（证明存在一条执行能触发 UNSAFE）**，那么 A 通常就够了，B 确实更难、也未必值得做。我们考虑 B 的主要原因不是“对所有调度都必须到达 MAX-1”，而是三点工程动机：

1) **减少伪泵/提高可解释性**：A 很容易“只增一次”，但并不能推出“能增 65535 次”；B（或更弱的 repeatability/closure 精化）是在补这个缺口。  
2) **减少对特定调度的依赖**：有些泵只有在非常脆弱的调度下才成立；B 相当于证明“一类插入的包/事件不会影响泵”，让结论不那么依赖某个极端的 interleaving。  
3) **让自动化更稳**：当验证器需要在海量交错里“猜”那条脆弱调度时会非常慢；把无关 step 证明为可交换/无关，可以显著缩小搜索空间（这也是 POR/commutativity 的直觉来源）。

**再回答一个更直接的问题：为什么 nondet 的 pump 似乎能“推出 MAX-1 可达”？**  
严格来说：**pump 阶段本身并不会让求解器真的跑到 `MAX-1`**。它只做了一件事：让求解器找一个 “前缀 + 循环段（lasso）” 的 witness，使得：

- 在某个 cutpoint 状态 `S` 之后，
- 再次回到 cutpoint 的状态 `S'`，
- 并且在我们选择的“投影/闭包条件”下 `S` 与 `S'` 等价，同时目标寄存器净 `+1`。

如果这个等价关系足够强（例如等价于“真正回到同一状态”，或满足我们想要的闭包谓词 `P`），那么你就可以把同一个循环段重复执行 `k` 次：每重复一次净 `+1`，从而在数学上推出“存在一条执行”能把寄存器推进到任意值（包括 `MAX-1`）。这一步不需要显式展开 `2^w-1` 次，而是基于“循环可重复”做归纳推理。

但注意这也是我们反复强调要做 closure_check/精化的原因：如果你的投影太弱，`S` 与 `S'` 只是在“你没看的那些变量”上发生了变化，那么循环段可能根本 **不可重复**。一个典型反例是：

- 第一次 `WRITE` 时 `seq_reg[idx]++`，同时把一个隐藏状态位 `stop := true`；
- 之后 `stop==true` 时 `WRITE` 不再自增；
- 若 `stop` 没被纳入投影，pump 可能仍然“看到一次 +1”，但它无法支撑“能泵到 MAX-1”。

因此，**“pump → MAX-1 可达”并不是自动成立的**：它依赖“循环段真的可重复”的闭包证据。A 给的是存在性循环证据；closure_check/repeatability/CEGAR 的作用就是把这份证据补强到足以支撑 `MAX` 快进。

### 5.4 confirm：在全语义模型里快速触发真实断言

confirm 阶段更简单：在进入 `while(true)` 前插入：

- `call reg.write(idx, MAX);`（对相关寄存器槽位）

然后在很短的 unroll 后缀中检查原本的性质断言。

对应实现：`dslc/transform/wraparound.py` 中 `WraparoundStage.CONFIRM` 分支（插入 `_emit_confirm_init`）。

> confirm 会把所有断言改写为 `call __wraparound_assert(cond)`，将多个断言点合并到一个错误位置，通常能减少 Ultimate 的“多目标”负担（语义等价）。

### 5.4.1 “closure_check 通过后，怎么得到一个 MAX(=65535) 的 Boogie 状态去求 bug？”

把它拆成“你能在代码里看到的两步”会更清楚：

**第一步：证明 closure_check（闭包泵）**

你运行的是 `closure_check` 变体。它把 `mainProcedure()` 的循环展开成 **一个 round（loop-free）**，并插入断言去证明：

- round 前后回到同一投影类（闭包）
- 目标寄存器副本净 `+1`
- 回到 cutpoint（例如 `procurator_phase == 0`）

Ultimate 若报告 `RESULT: ... correct`，就意味着这个 round 摘要在当前输入/调度约束下成立；这就是我们把 “写到 MAX” 当成摘要步的依据。

> 可选：如果 `closure_check` 暂时证明不了，可以先跑 `pump` 变体让工具给出一个“存在性 +1 闭合”的 witness，用来定位闭包谓词缺了哪些变量，再去精化投影或环境约束。

**第二步：构造一个“快进到 MAX”的验证任务，然后检查真实断言**

当前仓库里有两种方式（都属于 acceleration 思路）：

1) **confirm（最稳、最简单）**：直接在进入 `while(true)` 前插入 `call R.write(idx, MAX);`，让验证从临界点附近开始，再用很短的 suffix（例如 unroll=3）检查真实性质是否违反。  
   - 优点：通常最快、最容易稳定出 witness。  
   - 局限：它本身不证明 `MAX` 从初态可达，因此更偏向“bug-finding/诊断”。

2) **accel（把快进写进同一份模型）**：在运行时先等待检测到“可快进条件”成立，再在模型内执行 `call R.write(idx, MAX);` 做快进，然后继续跑并检查真实断言。  
   - 这相当于把“检测快进条件 + confirm”合并成一次验证任务（但目前在 TraceAbstraction 下不一定更快）。

这两种方式的共同点是：它们都不显式模拟 “从 0 加到 65535 的 65535 次更新”，而是把这段超深前缀用一个“快进写回（summary step）”代替。

> 如果你希望把“快进到 MAX”的合理性再往前推一步（更像证明），下一步通常是：用 pump witness 提取循环片段，并把投影逐步扩展到“循环在全状态上可重复”。这就是为什么我们把 proj/cutpoint 设计成一个可调旋钮：它决定了 pump 的“证据强度”。

### 5.5 为什么这比“直接设初值=65535”更有意义

- `confirm` 单独使用确实是“从临界状态出发”，不保证可达性（它更像条件反例：if `MAX` reachable）。
- `closure_check` 成功时给出的是一个更强的证据：在选定 cutpoint/投影与输入约束下，每一轮 round 都净 `+1` 且闭包，因此可以推得 `MAX` 可达（无需展开 65535 次）。
- 因此 `closure_check -> confirm` 可以被解释为：**我们先证明“能推进到临界前沿”的闭包泵成立，再在全语义下检查翻转后缀是否会导致真实性质违反**（必要时再用 pump witness 做诊断/精化）。

---

## 6 实现（Implementation）

### 6.1 DSL 编译与 Boogie 生成

- `dslc/compiler.py`：解析 `.prop` → 语义检查 → 调用后端
- `dslc/backends/boogie.py`：后端入口（仅 re-export `BoogieBackend`）
- `dslc/backends/boogie_backend.py`：Boogie 后端编排（调用 P4B、前缀化、寄存器写插桩、拼接节点 + harness）
  - 调 P4B：`dslc/backends/boogie_p4b.py:P4BTranslator.compile_to_bpl`（支持 `--goto/--meta-out/--bmv2cmds/--slicing-vars`）
  - 前缀化：`dslc/backends/boogie_prefix.py:BoogiePrefixer`（避免命名冲突；跳过 `$builtin/{:inline ...}` 等）
  - 寄存器写插桩：`dslc/backends/boogie_registers.py:instrument_register_writes`（last/index0 追踪变量）
- `dslc/backends/boogie_harness.py`：系统级 harness 生成（sequential/concurrent；队列/事件语义；assert/trace）
- `dslc/backends/boogie_seeds.py`：分布式 slicing 种子与 `hdr.*` 反向传播（用于全局剪枝/收紧 env havoc）

其中，**slicing + env-input pruning** 的关键准则是“职责分离”：

- **Property seeds（切片准则）**来自 `assume/assert`（约束可行性/性质可观测量）与 node/host 的**非 env** DSL 语句里引用到的 P4 变量。
- `env { ... }` 是输入注入建模（注入时刻对包字段赋值/收紧），**不作为切片 seeds**；否则会把“为了构造包而写的字段”误当作性质观测量，导致切片被动保留大量无关逻辑（例如 DistCache 的 value 路径）。
- 若存在 `topology { link ... }`，由系统层补充 **Communication seeds**（转发/事件控制变量，如 `standard_metadata.egress_port/egress_spec`、`p4b_clone_*`、`p4b_recirculate`），避免切片删掉“影响下游可达性”的通信语义。
- 多节点时沿拓扑反向传播的 packet seeds 只传播 `hdr.*`（on-wire 字段），不传播 `meta.*`/`standard_metadata.*`（节点本地）。

同时，为了让 “slicing + pruning” 在工程上可用（不会因为 slice 后符号消失而让 Boogie 直接 typecheck 失败），我们在生成 harness 时做了两件配套处理：

- **env 语句过滤**：如果 `.prop` 的 `env { ... }` 引用到的字段在 slice 后已经不再声明，`dslc` 会自动丢弃这条 env 语句（否则会触发 Ultimate 的 Boogie TypeChecker error）。
- **寄存器写入追踪（ghost instrumentation）**：对每个 P4 register 数组 `R` 注入 `R__wrote_any / R__last_index / R__last_value / ...`，并在 `R.write` 中更新；这样可以写出更“功能性”的性质（例如“某个寄存器应该被写到”，而不是只看最终数值），也便于对照 witness/trace。

在本次 wrap-around 实验中，我们使用 **sequential harness**，以便 wraparound 变换能稳定定位：

- `mainProcedure()` 的 `while(true)`
- 其中的 `call main();` 与 `procurator_step := procurator_step + 1;`

### 6.2 wraparound 变换（Boogie→Boogie）

实现文件：`dslc/transform/wraparound.py`

关键点：

- 通过解析 Boogie 声明找出目标寄存器数组的位宽（`[bvX]bvW`）：`analyze_bpl_for_wraparound`
- 只在 `mainProcedure()` 内插桩，保证变换局部化
- 为了便于回归/对照：如果输出内容不变，就不重写 `.bpl`（减少无意义的 mtime 变化）：`instrument_bpl_file`/`unroll_mainprocedure_loop_file`

### 6.3 端到端脚本（产物对齐 + 可复现）

实现文件：

- `dslc/workflows/wraparound.py`：只生成产物（base `.bpl` + staged `.bpl` + manifest），不跑 Ultimate
- `dslc/cli/wraparound.py`：端到端 runner（入口：`./bin/procurator wraparound`，默认 no-cache，每次运行在新的 `<OUT_DIR>` 下产物隔离）

它负责把多个部件串起来：

1. 先生成 base `.bpl`（忠实语义）
2. 从 `.prop` 的 `global assert` 自动推断（目标寄存器名、idx）：
   - 例如 `s1_sequence_reg_0[0] >= s2_sequence_reg_0[0]`
3. 生成各 stage `.bpl`：closure_check/pump/accel/accel_probe/confirm
4. （可选）调 Ultimate CLI 跑，并把日志写到 `<OUT_DIR>/*.gemcutter.log`（以及 witness 到 `<OUT_DIR>/*.bpl-witness.graphml`）

### 6.4 Ultimate 工具链配置

本次实验分两类任务：

- `closure_check`（SAFE 证明）：优先用不输出 witness 的 reachability 流水线，减少开销
- `confirm`（UNSAFE 找 bug）：用带 WitnessPrinter 的 reachability 流水线输出 GraphML

**关于 fork 并发 vs 顺序 harness 的工具选择**

- 如果输入 Boogie 含 `fork`（concurrent harness），优先使用 **GemCutter**（并发验证器）；很多顺序后端并不支持带 `fork` 的 Boogie。
- 如果输入 Boogie 不含 `fork`（sequential harness），则可以使用 TraceAbstraction/Automizer 等顺序后端做证明/找 bug。
- 本报告的 wrap-around 任务生成器目前强制 `--boogie-harness sequential`（见 `dslc/workflows/wraparound.py`），因为它需要稳定定位 `mainProcedure/while(true)` 并插桩；把它推广到 fork harness 需要单独的变换/或先做等价顺序化。

其中 `confirm` 使用的“ReachSafety + Witness”流水线为：

- toolchain：`dslc/toolchain/ultimate/ReachSafety-Witness.xml`
- settings：`dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-witness.epf`
  - 外部求解器：Z3（ALL）
  - 启用 WitnessPrinter：输出 `*.bpl-witness.graphml`

`entry_check / closure_check` 使用的配置为：

- toolchain：`dslc/toolchain/ultimate/ClosureCheck-ReachSafety.xml`（不含 WitnessPrinter，避免 correctness witness 的已知崩溃）
- entry_check settings：`dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-witness.epf`（更偏 bug-finding/可达性，避免在 Netchain 上出现病态长时间）
- closure_check settings：`dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por.epf`
  - 关闭 per-query Z3 timeout（避免 UNKNOWN）
  - `HoareAnnotationPositions=None`（避免 SAFE 后的额外 simplify 卡顿）
  - 关闭并发 POR（sequential round proof 不需要）

此外，我们也提供了一个带 `icfgtransformation` 的 toolchain，用于后续 loop acceleration 实验（本报告不把它纳入主结果）：`dslc/toolchain/ultimate/ReachSafety-Transformed-Witness.xml`。

---

## 7 评估（Evaluation）

### 7.1 实验设置

**硬件/软件**

- CPU：AMD Ryzen 7 7745HX（16 vCPU）
- 内存：15GiB
- Z3：4.8.12
- Ultimate：0.3.1-dev-d36a0da05e-m（见日志开头 “This is Ultimate …”）

**基准与性质**

- Netchain（bv16 wrap-around）
  - P4 程序：`Procurator/argo/code/dataset/Netchain/netchain_16.p4`
  - 控制面表项：
    - s1：`Procurator/argo/code/dataset/Netchain/commands_1.txt`
    - s2：`Procurator/argo/code/dataset/Netchain/commands_2.txt`
  - DSL spec：`Procurator/argo/code/spec/bench/netchain_bug_s1s2.prop`
    - 2 节点拓扑：`s1 -> s2`
    - 收紧输入：只发 `NC_WRITE_REQUEST`，key 固定到 index 0，overlay terminator 固定等
    - 性质（safety）：`assert { s1_sequence_reg_0[0] >= s2_sequence_reg_0[0]; }`
- DistCache（bv32 wrap-around，clientTrack-only demo）
  - P4 程序：`Procurator/argo/code/dataset/distcache/clientrackswitch/partitionswitch.p4`
  - 控制面表项：`Procurator/argo/code/dataset/distcache/clientrackswitch/clienttrack_entries.txt`
  - DSL spec：`Procurator/argo/code/spec/bench/distcache_leafload_wraparound.prop`
    - 强制走 `update_leaf_load` 更新路径（`optype=0x2009`），每个 round 自增一次 `leafload_reg`
    - 固定 `clientTrack_meta.leafswitchidx == 2`（使被更新的寄存器槽位稳定）
    - 性质（safety）：`assert { clientTrack_leafload_0 != 0; }`（翻转后变 0）

**计时口径**

下表中的时间来自 Ultimate 日志末尾的 `OverallTime`（TraceAbstraction/Automizer 统计），不包含 P4→Boogie 翻译时间。

### 7.2 结果总览

表 1：认证版 wrap-around 管线（entry_check + closure_check + confirm）的结果。

| 基准 | 阶段 | 输入 BPL | 结果 | elapsed_s (s) | witness 大小 |
|---|---|---|---|---:|---:|
| Netchain | entry_check | `<OUT_DIR>/netchain_bug_s1s2.entry_check.bpl` | UNSAFE | 355.4 | — |
| Netchain | closure_check | `<OUT_DIR>/netchain_bug_s1s2.s1_sequence_reg_idx0_global_asserts.closure_check.bpl` | SAFE | 507.4 | — |
| Netchain | confirm.unroll3 | `<OUT_DIR>/netchain_bug_s1s2.s1_sequence_reg_idx0_global_asserts.confirm.unroll3.bpl` | UNSAFE | 69.6 | 553,381 B |
| DistCache | entry_check | `<OUT_DIR>/distcache_leafload_wraparound.entry_check.bpl` | UNSAFE | 104.8 | — |
| DistCache | closure_check | `<OUT_DIR>/distcache_leafload_wraparound.clientTrack_partitionswitchIngress_leafload_reg_idx2_boogie_counter_write_clientTrack_leafload_0_idx_from_global_assume_2.closure_check.bpl` | SAFE | 79.9 | — |
| DistCache | confirm.unroll3 | `<OUT_DIR>/distcache_leafload_wraparound.clientTrack_partitionswitchIngress_leafload_reg_idx2_boogie_counter_write_clientTrack_leafload_0_idx_from_global_assume_2.confirm.unroll3.bpl` | UNSAFE | 57.2 | 511,951 B |

**端到端结论（本次的主线）**

- 对 Netchain（bv16），认证版三阶段总计约 **932s（≈15.5 分钟）** 得到可解释的反例工件（log + GraphML witness）。
- 对 DistCache（bv32，clientTrack-only），认证版三阶段总计约 **242s（≈4.0 分钟）** 得到反例工件。

### 7.3 反例是否“符合预期”（语义 sanity check）

在 confirm 阶段，最终触发的断言被改写为：

```
call __wraparound_assert(bvule.bv16$builtin(s2_sequence_reg__dbg0, s1_sequence_reg__dbg0));
```

即验证 `s2_seq <= s1_seq`（等价于 `s1_seq >= s2_seq`）。在触发点的 valuation（见 `<OUT_DIR>/netchain_bug_s1s2...confirm.unroll3.gemcutter.log`）包含：

- `old(s1_sequence_reg__dbg0)=0bv16`
- `s2_sequence_reg__dbg0=65535bv16`

因此 `65535 <= 0` 为假，断言被真实违反，这与“翻转导致关系断裂”的预期一致。

对 DistCache（clientTrack-only）同理：在触发点的 valuation（见 `<OUT_DIR>/distcache_leafload_wraparound...confirm.unroll3.gemcutter.log`）包含：

- `clientTrack_leafload_0=0bv32`
- `clientTrack_partitionswitchIngress_leafload_reg__last_index=2bv32`

与 spec 中的 `assert { clientTrack_leafload_0 != 0; }` 直接矛盾，说明翻转后缀确实进入了违反状态，而不是“MAX 初始值导致的翻转前伪反例”（confirm 阶段对 `MAX` 做了断言门控）。

---

## 8 局限性与下一步（Limitations & Next Steps）

### 8.1 当前 wrap-around 加速的边界

- **依赖 sequential harness 形状**：变换目前要求存在 `mainProcedure()` + `while(true)` + `call main()` 的结构，因此主要服务于 sequential harness。对于 fork 并发 harness，当前推荐做法是：直接生成等价的 sequential harness 来做 wrap-around（在 pass-atomic + 全局锁 的语义下两者只是编码不同）；若要直接在 fork 程序上插桩，需要单独适配 cutpoint/round 的定位与插桩点。
- **投影选择会影响健全性/性能**：
  - 投影太弱：可能出现“伪泵循环”（循环在真实状态空间不可重复），导致 confirm 从 MAX 出发能触发 bug，但 pump 的“可达性证据”不够强。
  - 投影太强：很难闭合循环，pump 变慢或找不到 witness。
  - v0/v1 的正确方向应当是 CEGAR：从小投影开始，出现伪证据就扩投影。

### 8.2 为什么 accel 阶段目前不如两段式（closure_check→confirm）稳定

`accel` 把快进写回直接编码在模型里，等价于把两段式合并成一次大查询。直觉上它可能更快，但在 TraceAbstraction 下它会：

- 引入额外控制流与写回动作，扩大公式/自动机差分的负担
- 仍然需要在同一份模型内同时解决“发现循环”和“触发真实断言”，导致 CEGAR 更难收敛

因此短期更可控的策略是：**保持两段式**（`closure_check` 给出闭包泵证明，`confirm` 回到全语义确证；必要时再用 `pump` witness 做诊断/精化）。

### 8.3 想做到“分钟级”的主要抓手

基于当前实现与日志剖析，最直接的加速路径通常不是“加更多开关”，而是围绕两点：

1. **更强的投影收紧（但可解释）**：把与泵循环无关、但导致等价类难闭合的变量剔除/抽象化。
2. **更小的错误目标（更少错误位置）**：我们已在 confirm/accel 中使用 `__wraparound_assert` 合并断言点；同理可对 pump/accel 的检测点做更强的结构化输出，降低 Ultimate 的目标数量。

---

## 9 复现（Artifact & Reproducibility）

**直接复现本报告的认证版（entry_check + closure_check → confirm）结果（推荐）**

- 产物与日志位置：每次运行会输出一个新的 `<OUT_DIR>`（形如 `.tmp/procurator/wraparound/<spec>/<run_id>/`）：
  - base `.bpl`：`<OUT_DIR>/<stem>.base.bpl`
  - stage `.bpl`：`<OUT_DIR>/<stem>.<stage>.bpl`
  - log：`<OUT_DIR>/<stem>.<stage>.gemcutter.log`
  - witness：`<OUT_DIR>/<stem>.<stage>.bpl-witness.graphml`（主要看 confirm 阶段）

**命令（示例）**

使用 wraparound runner（会自动编译 base `.bpl`，默认跑 `entry_check,closure_check,confirm`，并在满足 soundness gate 时输出 `[CERT] UNSAFE`）：

```
./bin/procurator wraparound \
  --spec Procurator/argo/code/spec/bench/netchain_bug_s1s2.prop \
  --p4b-bin P4B-Translator/build-host/p4c-translator \
  --ultimate ./UGemCutter-linux/Ultimate \
  --stages closure_check,confirm \
  --confirm-unroll 3
```

```
./bin/procurator wraparound \
  --spec Procurator/argo/code/spec/bench/distcache_leafload_wraparound.prop \
  --p4b-bin P4B-Translator/build-host/p4c-translator \
  --ultimate ./UGemCutter-linux/Ultimate \
  --stages closure_check,confirm \
  --confirm-unroll 3
```

> `./bin/procurator wraparound` 默认 no-cache：每次 run 都在新的 `<OUT_DIR>` 下产物隔离。如果你想复现/对照同一路径，可显式指定 `--out-dir <dir>`。

---

## 10 相关工作（Related Work，简述）

这部分只覆盖“与本实现直接相关、且我们确实用到了的概念/工具”，并给出可对齐的引用（后续写论文时需要进一步补齐比较实验与更系统的 related work）：

- **Lasso / Pump（最终周期性反例）**：LTL 的 automata-theoretic 传统表明，反例可表示为 “前缀 + 循环”（ultimately periodic / lasso）[1]；工程实现中也大量使用该形状做 LTL 反例搜索与重放 [2]，并且近年来也有面向 infinite-state 的 LTL falsification 实践 [3]。我们在 wrap-around 深 bug 上用的 `pump` witness 属于同一“最终周期性结构”的变体，只是把循环的语义从 Büchi 环换成了“cutpoint 闭合 + 寄存器净 +1”。
- **闭包/可重复性（closure pump 的思想来源）**：为了避免伪泵，我们需要证明某个谓词对 round 转移闭包，这与非终止证明里常见的 recurrent set / proving nontermination via safety 的思路一致 [8,9,10]。
- **循环加速/摘要（为何不展开 2^w 次）**：从验证角度看，wrap-around 是典型“需要跨过超深前缀”的计数器问题；程序加速/正则模型检查等方向提供了把循环净效应摘要为 transitive closure 的方法论与工具化路径 [5,6,7,11]。
- **P4→Boogie 前端**：我们复用了 P4b/P4B 的 “P4→Boogie” 翻译路线作为单节点语义底座 [12]。
- **通用并发验证工具链**：Ultimate 的 TraceAbstraction/GemCutter 提供了我们当前使用的并发/证明取向后端（commutativity/CEGAR 等）[14]。
- **领域定制网络验证**：NetSMC 展示了“针对状态化网络系统做定制模型检查器”的经验与 trade-off，这也支撑我们在 harness/抽象上做领域化取舍 [13]。

---

## 结论（Conclusion）

本报告把 Procurator 当前的“DSL→Boogie 分布式语义编码 + Ultimate 验证”实现拆解成可读的设计与实现对应关系，并针对 Netchain 的 wrap-around 深反例给出一个可落地的加速工作流：用 `closure_check` 证明闭包泵成立（从而支撑 `MAX` 可达），再用 `confirm` 在全语义下快速确证翻转后缀的真实性质违反。在我们的复现实验中，该流程把“可能数小时无结果”的深 bug 搜索压缩到分钟级，并产出可审计的 GraphML witness，具备进一步系统化与论文化的基础。

---

## 参考文献（References）

[1] Moshe Y. Vardi. *An automata-theoretic approach to linear temporal logic*. 1996. doi: `10.1007/3-540-60915-6_6`

[2] Stefan Edelkamp, Shahid Jabbar. *Large-Scale Directed Model Checking LTL*. 2006. doi: `10.1007/11691617_1`

[3] Alessandro Cimatti, Alberto Griggio, Enrico Magnago. *LTL falsification in infinite-state systems*. 2022. doi: `10.1016/j.ic.2022.104977`

[4] Matthias Heizmann, Jochen Hoenicke, Jan Leike, Andreas Podelski. *Linear Ranking for Linear Lasso Programs*. 2013. doi: `10.1007/978-3-319-02444-8_26`

[5] Marius Bozga, Radu Iosif, Filip Konečný. *Fast Acceleration of Ultimately Periodic Relations*. 2010. doi: `10.1007/978-3-642-14295-6_23`

[6] Ahmed Bouajjani, Bengt Jönsson, Marcus Nilsson, Tayssir Touili. *Regular Model Checking*. 2000. doi: `10.1007/10722167_31`

[7] Ahmed Bouajjani, Peter Habermehl, Tomáš Vojnar. *Abstract Regular Model Checking*. 2004. doi: `10.1007/978-3-540-27813-9_29`

[8] Ashutosh Gupta, Thomas A. Henzinger, Rupak Majumdar, Andrey Rybalchenko, Ru-Gang Xu. *Proving non-termination*. 2008. doi: `10.1145/1328438.1328459`

[9] Hong-yi Chen, Byron Cook, Carsten Fuhs, Kaustubh Nimkar, Peter W. O’Hearn. *Proving Nontermination via Safety*. 2014. doi: `10.1007/978-3-642-54862-8_11`

[10] Alexey Bakhirkin, Nir Piterman. *Finding Recurrent Sets with Backward Analysis and Trace Partitioning*. 2016. doi: `10.1007/978-3-662-49674-9_2`

[11] Colas Le Guernic. *Toward a Sound Analysis of Guarded LTI Loops with Inputs by Abstract Acceleration*. 2017. doi: `10.1007/978-3-319-66706-5_10`

[12] Chong Ye, Fei He. *P4b: A Translator from P4 Programs to Boogie*. 2023. doi: `10.1145/3611643.3613091`

[13] Yifei Yuan, Soo-Jin Moon, Sahil Uppal, Limin Jia, Vyas Sekar. *NetSMC: A Custom Symbolic Model Checker for Stateful Network Verification*. NSDI 2020. https://www.usenix.org/system/files/nsdi20-paper-yuan.pdf

[14] Azadeh Farzan, Dominik Klumpp, Andreas Podelski. *Sound sequentialization for concurrent program verification*. 2022. doi: `10.1145/3519939.3523727`
