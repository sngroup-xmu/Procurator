# Procurator（本仓库）当前实现：设计/转换/验证/选项/优化综述

这份文档站在“代码现状”的角度，解释本仓库**现在**是怎么把一个分布式 P4 系统编译成可验证模型、再交给验证后端跑起来的；同时把“可用的开关/选项”与“已经实现的优化”整理成一份清单，最后专门解释一下为什么 **计数器翻转（wrap-around）** 这类 bug 会让求解器很难在短时间内给出答案，以及我们可行的改进方向。

> 说明：仓库根目录 `AGENTS.md` 更像是“vNext 设计文档/研究计划”；本文是“实现状态与工程接口说明”。

---

## 1. 目标与两条验证产线（Promela vs Boogie）

本项目的统一输入是 DSL 规格文件（`.prop`），描述：

- 多个节点（每个节点导入同一个或不同的 P4 程序 + 控制面表项）
- 拓扑（节点之间如何转发/入队）
- 环境输入约束（节点/host 的 `assume { ... }` 与 `env { ... }`）
- 性质（目前主要是 safety：`assert { ... }`）

目前有两条产线：

1) **DSL → Promela → SPIN**（`dslc/backends/promela.py`）  
   - 适合 LTL（SPIN 原生支持），但目前 Promela 后端对“把 DSL 语句插入到每个节点的 Promela 过程里”比较保守（避免 fragile 的文本拼接），因此主要依赖全局性质与环境约束。

2) **DSL → Boogie → Ultimate/GemCutter**（`dslc/backends/boogie.py`）  
   - 适合 safety/可证明取向（GemCutter 的 CEGAR + commutativity 思路）。
   - 重点在“分布式 pass-atomic 语义 + P4-aware 剪枝/约束 + 并发/串行两种 harness”。

本文主要围绕 Boogie/GemCutter 这条主线展开。

---

## 2. Repo 里的关键入口

### 2.1 DSL 编译器入口

- `dslc/compiler.py`：通用编译入口（支持 `--backend promela|boogie`）。
  - 用法示例（只编译 Boogie，不跑 Ultimate）：
    - `python3 -m dslc.compiler --backend boogie --spec <x.prop> --out <x.bpl> --p4b-bin <p4b-translator> --work-dir <dir>`

### 2.2 “编译 + 跑 GemCutter”的一键入口

- `Procurator/argo/code/spec/prop_compile/run_gemcutter.py`：常用一键脚本
  - 负责：调用 `dslc.compiler.compile_spec_file(...)` 生成 `.bpl`，再调用 Ultimate CLI 跑 GemCutter，并把日志写到 `.tmp/dslc/*.gemcutter.log`。

### 2.3 消融实验脚本

- `Procurator/argo/code/spec/prop_compile/run_ablation.py`：当前主要做 **symmetry / property-split** 两类消融矩阵。

### 2.4 Wrap-around 加速实验入口（V0-0/V0-1）

- `Procurator/argo/code/spec/prop_compile/run_wraparound.py`
  - 生成并（可选）运行 `closure_check/pump/accel/accel_probe/confirm` 变体，用于 “寄存器翻转（wrap-around）” 这类深前缀 bug 的加速实验。
  - `closure_check`（V0-1 主线）：生成 loop-free 的证明任务，证明 round 的闭包 + 净 `+1`（closure pump），作为 `MAX` 可达的证据。
  - `confirm`（V0-0）：在进入循环前把目标寄存器槽位写到 `MAX`，再用很短的 unroll suffix 检查是否能触发断言违反。
  - `pump`（可选诊断）：找 “`+1` 的泵循环 witness”（存在性证据），用于定位闭包谓词/投影缺口（CEGAR/调试）。
  - `accel_probe`：只验证“加速触发条件可达”，便于诊断 `accel` 为什么跑不出来（同样输出 witness）。
  - `accel`（实验中）：把“检测到泵循环”编码到模型里，并在模型中执行加速写回；当前仍可能超时，推荐先用 `closure_check -> confirm` 两段式跑通端到端。
  - 工程化特性：
    - 默认 stages 为 `closure_check,confirm`；`--rerun` 可强制重跑并刷新输出
    - `--require-closure`：`closure_check` 不是 `correct` 时拒绝跑 confirm/accel（soundness guard）
    - 复用输出（log/witness）：当输出新于输入 `.bpl` 时，对应 stage 会直接 `[SKIP]`（便于把“日常复跑”降到秒级/分钟级）
    - 支持对单独 stage 覆盖 toolchain/settings（例如只对 `pump` 启用 `icfgtransformation`）

---

## 3. DSL（`.prop`）能写什么：语义上对应哪一层

DSL 语法在 `dslc/speclang/grammar.py`，模型结构在 `dslc/speclang/model.py`，解析逻辑在 `dslc/speclang/parse.py`。

### 3.1 核心块

- `import s1 from ".../x.p4" entries ".../commands_1.txt";`
  - 每个 import 生成一个节点实例（Boogie 里会统一加前缀 `s1_`、`s2_` 防止命名冲突）。
- `topology { link s1 -> s2 ALL; }`
  - 定义“转发的 egress_port 命中后，如何入队到下游节点”。
- `node s1 { ... }` / `host h1 { connect s1; ... }`
  - `assume { ... }` 用于收紧输入空间（非常关键）。
  - `env { ... }` 用于“注入时刻”的赋值/约束（比单纯 assume 更像“host 生成包”）。
- `global { ... }`
  - 放全局 assume/assert、调度/环境开关、对称性声明等。

### 3.2 DSL 的“全局配置指令”（目前实现了哪些）

这些配置在 `dslc/speclang/parse.py:_DSL_CONFIG_DIRECTIVES` 里列出来了：

- `queue_capacity = <int>;`
  - 控制 Bag(K) 中的 K（`inbox_count < K` 约束）。
- `max_steps = <int>;`
  - **注意：Boogie 后端目前刻意忽略它**（`dslc/backends/boogie.py` 里有注释：保持 unbounded loop，让 Ultimate 自己处理循环）。
  - 你可以把它当成“以后做 BMC/有界验证”的输入接口，但当前 GemCutter harness 不使用它做 cut。
- `deterministic_scheduler = true|false;`
  - 只影响 **Boogie sequential harness**：true 时生成 round-robin 调度（避免 nondet 分支、避免 modulo），便于 debug 深循环。
- `env_thread = true|false;`
  - 是否启用 EnvThread（外部输入注入者）。若你完全用 host 建模输入，可以关掉避免重复注入。
- `host_eager = true|false;`
  - host 发包是否“总是尝试发送”（true）还是 “nondet 发送”（false）。

### 3.3 LTL 在 DSL 里的地位（现在能不能用）

DSL 语法支持 `ltl { ... }`（见 `dslc/speclang/grammar.py`），Promela/SPIN 后端会把它翻译成 Promela 的 `ltl` 公式（`dslc/backends/promela.py` 里有实现）。

但 **Boogie/GemCutter 后端目前不编码 LTL**：

- Boogie 后端会在表达式层面“尽量解析 always/eventually”，但只会把 `[]P` / `<>P` 退化成 `P`（`dslc/backends/boogie.py:_expr_to_boogie` 里有 best-effort 逻辑）。
- 因此如果你的性质本质是 liveness（比如“最终一致性”），目前更现实的做法是：
  - 先把它改写成 safety（加监视器/ghost state，把 liveness-to-safety），或
  - 走 Promela/SPIN 做原型验证。

---

## 4. Boogie 后端：P4→Boogie + 分布式 harness 是怎么拼起来的

Boogie 后端核心文件：`dslc/backends/boogie.py`。

### 4.1 每个节点的 P4→Boogie 翻译（P4B-Translator）

对每个 `import s1 from ...`：

1) 调用 P4B-Translator（包装器：`P4BTranslator.compile_to_bpl`）：
   - 默认加 `--goto`（把控制流变成 goto-state machine，避免大 if-else 链干扰 Ultimate 的 atomic 分析）
   - 支持 `--fromJSON`（Tofino/bf-p4c JSON IR）
   - 支持 `--meta-out`（生成 `p4bmeta-v1`，用于类型/读写集/切片等）
   - 支持 `--slicing-vars=<...>`（把 slicing seeds 传给 P4B）

2) 对输出 `.raw.bpl` 做工程化修补：
   - 补缺失的变量声明（`_patch_missing_var_decls`，结合 `meta-out` 的类型信息）
   - 收集“外部输入字段列表”（`_collect_input_vars_and_egress_type`）
   - 若启用剪枝：过滤掉“只出现在 var 声明、但不出现在程序使用处”的输入字段，保证 env havoc 和 sliced 程序对齐（`_filter_input_vars_by_usage`）

3) 给每个节点整体加前缀（`BoogiePrefixer`）
   - 例如把 `hdr.ipv4.dstAddr` 变成 `s1_hdr.ipv4.dstAddr`
   - 并避免把 Boogie 内置的 bitvector builtin 名字也错改（否则会导致 BV 运算变成 uninterpreted）

### 4.2 分布式 harness：统一的 pass-atomic 语义

核心建模原则：**一次 pipeline pass（ingress→egress run-to-completion）是原子单位**，交错只发生在“下一次选择哪个节点执行 pass”。

当前队列/消息抽象：

- **Bag(K) + 单槽 mailbox**
  - 每个节点一个 `*_inbox_count` 计数器代表“队列里有多少个待处理包”（不保序）。
  - 包字段本身存在节点的全局变量里（`s1_hdr.*`、`s1_meta.*` 等），因此本质是“单槽 mailbox”：当 `inbox_count>1` 时，哪个包被处理是 over-approx 的 nondet。

并发/串行两种 harness（由 `--boogie-harness` 选择）：

1) **concurrent harness**
   - 生成 `fork ... NodeThread()` / `EnvThread()` / `HostThread()`；
   - 用一个 `procurator_lock` 实现“pass atomic”（atomic 块只包裹 lock acquire/release，尽量避免 Ultimate 的 atomic 组合问题）。

2) **sequential harness**
   - 生成一个 `while(true) { call main(); procurator_step++; }` 的单线程调度器；
   - 如果 `global.deterministic_scheduler=true`，调度器用 `procurator_phase` 做 round-robin（避免 modulo），减少求解器负担，适合 debug 深循环；
   - **`global.max_steps` 在这里被忽略**（当前就是 unbounded）。

### 4.3 两段式 pipeline（不是优化，是语义选择）

如果 `--no-two-stage` 没开，Boogie 后端会尝试把每个节点的 `mainProcedure` 拆成：

- `s1__procurator_ingress()`：Parser + verifyChecksum + ingress
- `s1__procurator_egress()`：egress + computeChecksum + forwarding/enqueue

目的：更接近某些硬件/IR 的行为（尤其是 clone/recirc 等“在 ingress/egress 边界产生事件”的语义），同时让调度器可把 ingress/egress 分成不同“actor”。

### 4.4 clone / recirculate / mirror 的桥接

如果节点 Boogie 里声明了 P4B 约定的标志位（如 `p4b_recirculate`, `p4b_clone_*`），harness 会：

- 在 ingress 开始前清零标志位；
- 在 ingress/egress 结束时根据 flag 决定是否额外入队或额外安排一次 egress；

对应实现：`dslc/backends/boogie.py:_emit_ingress_stage_body` / `_emit_egress_stage_body`。

### 4.5 跨节点转发只复制 `hdr.*`

在真实网络里，跨交换机传输的是 packet bits。

因此 `s1 -> s2` 的 enqueue 过程必须只复制 on-wire 字段：

- 当前实现用 `_is_on_wire_packet_var(name) -> name.startswith("hdr.")` 来保证只复制 header。

如果这点做错，会造成非常隐蔽的：

- 伪反例（因为 meta 被错误共享，等价于把多节点当成单进程）
- 漏判（因为某些本该节点本地重新计算的 meta 被“继承”了）

### 4.6 示例：Netchain 的 P4 ↔ Boogie 逐行对照（保真 sanity check）

为避免每次都依赖 `.tmp/` 里的生成产物，这里把一个最小但覆盖关键语义点的对照片段固定在 `doc/examples/`：

- P4 片段：`doc/examples/netchain_16_excerpt.p4`
- Boogie 片段：`doc/examples/netchain_bug_s1s2_seq_excerpt.bpl`

下面用“逐行”方式展示几个典型的 1:1 对应关系（左边是 P4，右边是 Boogie）：

| P4 | Boogie | 含义 |
| --- | --- | --- |
| `doc/examples/netchain_16_excerpt.p4:29` | `doc/examples/netchain_bug_s1s2_seq_excerpt.bpl:16` | `packet.extract(hdr.ethernet)` → 过程调用；抽象语义是把 header 置为 valid |
| `doc/examples/netchain_16_excerpt.p4:30` | `doc/examples/netchain_bug_s1s2_seq_excerpt.bpl:17` | `transition select(...)` → `goto` + `assume` 分支（显式控制流） |
| `doc/examples/netchain_16_excerpt.p4:92` | `doc/examples/netchain_bug_s1s2_seq_excerpt.bpl:119` | `sequence_reg.read(...)` → Boogie 中的 `reg.read(reg, idx)`（作为表达式/函数） |
| `doc/examples/netchain_16_excerpt.p4:95` | `doc/examples/netchain_bug_s1s2_seq_excerpt.bpl:126` | `seq = seq + 1` → `add.bv16(...)`（bitvector 模 2^16 算术） |
| `doc/examples/netchain_16_excerpt.p4:87` | `doc/examples/netchain_bug_s1s2_seq_excerpt.bpl:140` | `hdr.overlay.pop_front(1)` → 展开为一串字段搬移 + `valid/isValid` 搬移 |
| `doc/examples/netchain_16_excerpt.p4:110` | `doc/examples/netchain_bug_s1s2_seq_excerpt.bpl:181` | `get_sequence.apply()` → `call s1_get_sequence_0.apply()`（表调用翻译为过程调用） |

此外，分布式 harness 还会把跨节点转发建模成 enqueue 过程（不属于 P4 语言本身，但属于系统语义）：

- `doc/examples/netchain_bug_s1s2_seq_excerpt.bpl:217`：`s1__enqueue_s2()` **只复制 `hdr.*`**，不复制 `meta.*`（避免跨交换机泄漏 metadata）。

更完整的 Netchain 排查/对照过程（含控制面表项、slicing 影响、反例形状等）见：`doc/netchain_translation_diagnosis.md`。

---

## 5. “有哪些选项可以调”：CLI 与 DSL 两层

### 5.1 运行脚本（推荐入口）：`run_gemcutter.py`

文件：`Procurator/argo/code/spec/prop_compile/run_gemcutter.py`

常用选项：

- `--env spec|max`
  - `spec`：注入时应用 `.prop` 里的 assume/env 约束（推荐）
  - `max`：输入完全 nondet（havoc，不加 assume），用于“最坏环境”压力测试
- `--no-prune`
  - 关闭 slicing + env-input pruning（会更慢，但更接近“全语义”）
- `--por`
  - 开启 commutativity-based POR（目前实现是“基于读写冲突的 guard 偏序”，不是完整 POR）
- `--boogie-harness concurrent|sequential`
  - 并发 harness 更贴近 GemCutter 的定位；串行 harness 更适合 debug/语义对照（尤其 deterministic）
- `--no-two-stage`
  - 关闭两段式 pipeline（可能影响 clone/recirc 等语义的可控建模）
- `--compose` / `--compose-max-nodes` / `--compose-jobs`
  - 把 `global.assert { ... }` 的“顶层合取”拆成多个子 spec 并行跑（提升吞吐）
- `--ultimate-async`
  - 后台跑 Ultimate，log 会持续更新（适合长跑）
- `--ultimate-timeout-seconds 0`
  - 0 表示不设超时（你现在就在用这个模式）

### 5.2 编译器入口：`python3 -m dslc.compiler`

文件：`dslc/compiler.py`

它提供的核心开关基本与 `run_gemcutter.py` 一致（`--env/--no-prune/--por/--boogie-harness/--no-two-stage`），区别是它**只负责编译**，不负责跑 Ultimate。

### 5.3 DSL 配置（写在 `.prop` 里）

见 §3.2：

- `queue_capacity`
- `deterministic_scheduler`
- `env_thread`
- `host_eager`
- `max_steps`（Boogie 后端目前不使用）
- `symmetry(s1,s2,...)`（Boogie 后端会加入 inbox_count 的对称性破缺约束）

---

## 6. 已实现的优化（哪些是真的“优化”，哪些是“为语义保真”）

这里按“对性能/状态空间”的影响强弱排序。

### 6.1 slicing + env-input pruning（最核心）

入口开关：`--no-prune`（默认不开，即默认启用 pruning）

做了两件事：

1) **seed-driven slicing（调用 P4B 的 slicer）**
   - seeds 来自：node/host/global 的 assume/assert + DSL 语句里出现的变量（见 `collect_slice_seeds()`）
   - 额外做了“沿拓扑反向传播 packet seeds”（`propagate_packet_seeds()`），确保上游节点保留下游需要的 `hdr.*` 字段。

2) **env-input pruning**
   - 只 havoc 那些在 sliced `.raw.bpl` 中“真的被用到”的输入字段（否则会制造无关分支、拖慢求解器）。

### 6.2 property split（compose 模式）

入口开关：`--compose`

- 把 `global.assert { A; B; C; }` 的“顶层合取”拆成多个子 spec 分别跑。
- 典型用途：分布式系统有很多全局断言时，先把它们拆开并行跑，提高整体吞吐。

### 6.3 symmetry（对称性破缺）

DSL 写法：`global { symmetry(s1, s2, s3); }`

- 目前实现是“对称节点的 inbox_count 做排序约束”（`assume s1_inbox_count <= s2_inbox_count <= ...`），属于轻量但可能收益有限。
- 更强的对称性破缺（比如对寄存器/全局状态做 canonicalization）目前未做。

### 6.4 POR（commutativity-based guards）

入口开关：`--por`

- 当前实现不是完整 POR，而是：
  - 为每个节点构建一个粗粒度读写集（包含 inbox/packet fields/部分 stateful rw + forwarding side effects）
  - 如果两个节点的读写集不冲突，就在调度处加入“偏好先调度低编号节点”的 guard（减少等价交错）
- 这更像“调度偏好约束”，属于 **保守的剪枝**。

### 6.5 “语义保真但也能减少伪反例”的工程修复

这些不一定是“加速优化”，但能显著减少伪反例/无效搜索：

- 跨节点只复制 `hdr.*`（避免 meta 泄漏）
- 寄存器显式初始化为 0（P4 语义要求；否则会出现大量凭空状态）
- bitvector builtin 属性修正（避免 BV 运算被当成 uninterpreted）

---

## 7. 当前痛点：wrap-around（变量翻转）类 bug 为什么这么难

以 Netchain 为代表，wrap-around bug 的结构通常是：

- 有一个 `bv16`（或 `bv32`）的计数器寄存器 `seq`；
- 每次处理某类请求都会做 `seq := seq + 1`（bitvector 意味着模 `2^16` 算术）；
- 性质是某种“单调性/一致性关系”（例如 `s1_seq >= s2_seq` 或 “副本间序关系”）；
- bug 发生在 `65535 + 1 -> 0` 这一刻（瞬间破坏单调关系）。

这类 bug 对求解器难，通常不是“模型不对”，而是**反例需要很深的执行前缀**：

- 从 `seq=0` 出发，要走到 `seq=65535` 至少需要 `65535` 次“真的执行到自增动作”的 pass。
- 在我们的分布式 harness 里，一次外部 write 往往要经历多个调度阶段（env 注入 / s1 ingress / s1 egress+enqueue / s2 ingress / s2 egress ...）。
  - 这会把“真实包数”放大成“调度步数”，常见是 10^5 量级。
- GemCutter 虽然是 unbounded verifier，但它的 CEGAR/插值过程仍然要在循环上做大量推理；当需要“推到很深才能看到不变量被破坏”时，自动机状态数会迅速增大，出现你现在看到的：
  - log 卡在 `Difference: Start difference...` 很久不动；
  - `z3` CPU 长时间高占用；
  - automaton state 数量上万（例如日志里出现 “First operand 26884 states ...”）。

换句话说：你直觉里说的“前缀很长”确实是一个核心原因（这里的 prefix 指 counterexample/loop execution prefix）。

更进一步的“工程化解决思路”（把深前缀替换为泵循环 + 加速 + 确证，并尝试放进 Ultimate toolchain）见：`doc/ultimate_wraparound_acceleration_design.md`。

---

## 8. 面向 wrap-around bug 的可能改进方向（尽量不做“针对某个系统的特化”）

下面这些是“方向总结”，便于后续我们逐项评估实现代价与收益：

1) **计数器加速（loop acceleration / counter abstraction）**
   - 识别形如 `x := x + 1 mod 2^w` 的更新，并把“重复执行很多次”的效果用一个符号化步长 `k` 概括成 `x := x + k`（或更激进：`x` 变成任意值）。
   - 这类加速需要配合“可达性确证”（否则可能引入伪反例），典型做法是 CEGAR：先用加速模型找反例，再回到精确模型验证反例是否可实现。

2) **把 liveness 风格的“最终发生翻转”改写成 safety**
   - 如果目标性质类似“最终一致性/最终会违反某个序关系”，它本质是 liveness；
   - 要交给 Boogie/GemCutter，通常要加一个监视器把它变成 safety（例如记录某些关键事件已经发生、再 assert 不可能进入 bad state）。

3) **位宽消融（bitwidth scaling）作为 debug/实验手段**
   - 把 `bv16` 临时缩到 `bv8`，wrap-around 只要 256 次就能出现；
   - 这对“论文里的定量消融/趋势验证”很有用，但对“严格 16-bit 语义的可达性证明”不是最终答案。

4) **进一步加强环境收紧（避免无关分支）**
   - wrap-around bug 往往只需要单一包形状反复出现；
   - spec 层面的 `assume`/`env` 如果没收紧到“几乎只有一条路径”，求解器会在无关路径上浪费巨大时间。

5) **把 `max_steps` 做成“外部 BMC driver”的一部分（而不是后端硬编码）**
   - 现在 Boogie 后端明确选择 unbounded；
   - 但工程上可以提供一个“有界 bug-finding 模式”：在外层 driver 生成 `for i in 0..N { step(); assert; }` 的 BMC harness（N 来自 `global.max_steps`），不改变后端默认语义。

---

## 9. 实际建议：你现在该怎么选开关（按用途）

**A) 语义对照 / debug（优先保真 + 可读）**

- `--boogie-harness sequential`
- `.prop` 里 `deterministic_scheduler = true; queue_capacity = 1;`
- `--env spec`
- 如需对照 translator：先 `--no-prune`，确认一致后再打开 pruning

**B) 性能优先的 bug-finding（尽量快找到“浅反例”）**

- `--boogie-harness concurrent`
- `--env spec`
- 默认 pruning（不要 `--no-prune`）
- 可尝试 `--por`、`symmetry(...)`、`--compose`（如果 assert 很多）

**C) wrap-around 类深反例（现在的真实难点）**

在“严格从 0 初态推到 65535 再翻转”的要求下，单纯靠现有 CEGAR 很可能会慢；更现实的路线是：

- 先用更强的环境收紧 + 更小位宽做趋势验证；
- 再引入“计数器加速 + 反例确证”的两阶段流程，系统性解决“深前缀”的难题。
