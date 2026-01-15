# Ultimate 集成方案：面向寄存器翻转（wrap-around）的“泵循环 + 加速 + 确证”管线（v0→v1）

> 目的：解决像 Netchain 这类 **bitvector 寄存器计数器翻转** 的“深反例（deep counterexample）”问题：从初态（寄存器=0）到 `MAX -> 0` 需要 `2^w-1` 次有效更新，GemCutter/Automizer 即使能做 unbounded 推理，也可能在几小时内难以产生 witness。
>
> 本文把可行路线细化为一个可落地的工程计划：先用现有 Ultimate toolchains 做可行性实验（v0），再把流程自动化并“丢进 Ultimate toolchain”里（v1）。

---

## 1. 背景与问题定义

### 1.1 为什么只盯寄存器单调性仍然难

在 P4 程序里，发生“翻转（wrap-around）”的通常只有寄存器/计数器类 state（bitvector 模加）。

即使我们把性质写得极简（例如只检查 `s1_seq_reg[0] >= s2_seq_reg[0]`），从初态跑到违反点仍可能需要：

- `2^w-1` 次 **确实走到“+1 更新”写回点** 的执行；
- 每次更新在分布式 pass-atomic 模型里又对应多步调度（env 注入、ingress、egress、enqueue、下游处理…），导致反例前缀非常深。

因此加速点不在“性质更简单”，而在“如何跨过深前缀”。

### 1.2 我们要做什么：不是 `Pre(Bad)`，而是 `Pre(wraparound)` + 全语义快速验证

你提出的策略是：

1) 先求 `Pre(wraparound)`：到达“即将发生翻转”的临界前沿；
2) 从该状态出发用 **全语义**（原 harness/原输入约束）再跑 1~几步，若翻转会导致违反，则很快得到 bug witness；否则可能不存在该类 bug（或需要更强环境/调度才能触发）。

关键挑战：`Pre(wraparound)` 自身仍然深，因此需要抽象/加速。

---

## 2. Ultimate 侧工具/算法调研（与本方案相关的最小集合）

### 2.1 Ultimate 的“组装方式”

Ultimate 的 CLI 运行由两部分组成：

- **toolchain XML**：插件流水线（`<plugin id="..."/>`）
- **settings EPF**：为插件配置算法/求解器/并发策略等参数

本仓库中你们当前常用（并发 Boogie reachability）的 toolchain：

- `ultimate/trunk/examples/concurrent/bpl/regression/ReachSafety.xml`
  - pipeline：`procedureinliner -> boogie.preprocessor -> rcfgbuilder -> traceabstraction`

### 2.2 TraceAbstraction（Automizer/GemCutter 的主体）

插件：`de.uni_freiburg.informatik.ultimate.plugins.generator.traceabstraction`

核心原理：CEGAR + 反例路径可行性检查 + 插值/谓词精化。

你们的 GemCutter settings（如 `Procurator/argo/code/spec/config/ReachSafety-32bit-GemCutter-ALL.epf`）还启用了并发相关策略：

- 并发自动机：`PARTIAL_ORDER_FA`
- 并发 POR：`PERSISTENT_SLEEP_NEW_STATES_FIXEDORDER`

这些能削减交错，但对“需要 2^w 次才能翻转”的深前缀帮助有限。

### 2.3 LTL/Büchi 路线（找 lasso/cycle 的现成管线）

toolchain：`ultimate/trunk/examples/toolchains/LTLAutomizer.xml`

pipeline：

- `boogie.preprocessor`
- `rcfgbuilder`
- `ltl2aut`
- `buchiprogramproduct`
- `blockencoding`
- `buchiautomizer`

注意：示例 settings `ultimate/trunk/examples/LTL/regression/bpl/LTLAutomizerBpl.epf` 中，`ltl2aut` 默认调用外部 `ltl2ba`：

- `/instance/de.uni_freiburg.informatik.ultimate.ltl2aut/Read property from file=true`
- `/instance/de.uni_freiburg.informatik.ultimate.ltl2aut/Path to LTL*BA executable=ltl2ba`

当前环境中没有 `ltl2ba/ltl3ba/spot`，因此 v0 优先采用“不依赖外部 LTL2BA”的方案；若后续要试 LTLAutomizer，我们需要把 `ltl2ba` 作为依赖补齐。

### 2.4 PDR 模式（更偏归纳，可能更适合深循环）

Ultimate 的 traceabstraction 在 settings 层支持 PDR 方向：

- `ultimate/trunk/examples/programs/regression/bpl/PdrAutomizerBpl.epf` 中：
  - `Compute Interpolants along a Counterexample = PDR`

该模式可能更擅长对深循环合成归纳摘要，但对 bitvector 模加是否有效需要实测。

### 2.5 Sifa（符号解释/流体抽象）

toolchain：`ultimate/trunk/examples/toolchains/Sifa.xml`

pipeline：

- `boogie.preprocessor -> rcfgbuilder -> sifa`

它更像“快速生成抽象/不变式”的分析器，可用来辅助我们自动选投影（等价类变量集）与收紧候选循环。

---

## 3. 核心设计：用“泵循环（pumpable loop）”替代“跑到 65535”

### 3.1 关键思想

直接求 `Pre(wraparound)` 深度太大，我们改为先找一个可重复执行的循环段（pumpable loop）：

- 该循环执行 1 次，使目标寄存器槽位净效应为 `+1 (mod 2^w)`；
- 同时系统回到“同一等价类”（投影相等），从而可以**重复执行任意次**（至少在抽象层面成立）。

一旦拿到泵循环，我们就能用“加速转移”把寄存器从 0 **直接跳到 MAX**，再用全语义验证翻转是否引发性质违反。

### 3.2 等价类/投影（projection）是方案成败关键

我们需要一个投影 `proj(s)`，用于判断“回到同一等价类”：

- `proj` 太小 → 可能把一些隐含状态忽略掉，导致“循环可重复”是伪的（会引入伪反例/伪前沿）。
- `proj` 太大 → 循环很难闭合（找不到泵循环），或者求解很慢。

因此 `proj` 必须走 CEGAR 风格：从小开始，出现伪反例就扩充投影。

---

## 4. v0 可行性实验（不改 Ultimate，只用现成 toolchain；先跑通再自动化）

### 4.1 v0 产物与接口

我们先做一个“外部编排”的实验管线：

1) **Pump 探测版本 BPL**（加少量 ghost 插桩，目标是找泵循环）
2) **Accel 版本 BPL**（加入加速转移，目标是快速到达 `Pre(wraparound)` 并触发/排除 bug）
3) **Full-semantics 确证版本 BPL**（不含加速，只收紧输入/调度；用于排除伪反例）

它们都通过 Ultimate CLI 跑（仍然是“丢到 Ultimate toolchain 里”），只是由 Python 脚本串起来。

### 4.2 阶段 A：用 reachability（TraceAbstraction/GemCutter）找泵循环（不依赖 LTL2BA）

> 关键点：泵循环检测可以编码成 **纯 safety reachability**，不必先上 LTLAutomizer。

#### 4.2.1 Pump 检测的 Boogie 插桩（概念模板）

在 harness 的“每个 step 后”插入如下逻辑（伪代码）：

- ghost 变量
  - `pump_snap_taken: bool`
  - `pump_inc_seen: bool`
  - `pump_snap_step: int`
  - `pump_loop_len: int`
  - `pump_proj_*`: 一组投影快照变量（见 4.2.2）
  - `pump_found: bool`（可选，便于日志/诊断）

- snapshot capture（存在见证，用 `havoc` 表达）
  - `havoc take_snap: bool;`
  - `if (!pump_snap_taken && take_snap) { pump_snap_taken := true; pump_snap_step := procurator_step; pump_proj_* := proj(state); pump_inc_seen := false; }`

- increment event detection（在“目标寄存器 + 目标槽位”的 `+1` 写回点置位）
  - `if (did_target_inc_this_step) { pump_inc_seen := true; }`

- loop closure detection（投影回到快照）
  - `if (pump_snap_taken && pump_inc_seen && proj(state)==pump_proj_*) {`
    - `pump_loop_len := procurator_step - pump_snap_step;`
    - `assert false; // found pumpable loop`
    - `}`

这会让 Ultimate 输出一个普通的 safety counterexample（witness），其中包含：

- 快照时刻（`pump_snap_step`）；
- 闭环时刻（触发 assert 的 step）；
- loop length（`pump_loop_len`）；
- 以及满足投影相等的约束（可用于下一阶段加速的 guard）。

#### 4.2.2 v0 投影（proj）如何选：从“最小可闭合”开始

v0 采用“够用即可”的默认投影（后续再 CEGAR 精化）：

- 调度相关：
  - `procurator_phase`（若使用 deterministic scheduler）
  - 或者 `choice`（若使用 nondet scheduler，需把 choice 暴露为变量）
- 队列相关：
  - `s1_inbox_count`, `s2_inbox_count`, ...
- 关键控制变量（使能 +1 更新的 guard）：
  - `meta.location.index`（目标槽位 index）
  - `meta.my_md.role`（是否走到“维护序列号”的角色）
  - 必要的表命中布尔（例如 `find_index.hit`）
- 输入形状（只保留必要的 hdr 字段，不要把整个 packet 都放进 proj）：
  - 例如 op 类型（write/request）、key 映射到 index 的字段、dstAddr 等

v0 的原则是：**先让泵循环能闭合并被找出来**。如果后续出现伪加速/伪反例，再把遗漏变量加回投影。

#### 4.2.3 “目标寄存器的 +1 写回”如何识别（必须做，不然会被伪循环淹没）

我们不能把“任意 write”都当成 `inc`，否则像 Netchain 里 `assign_value` 写固定 seq 值会触发大量伪循环。

v0 做一个足够实用的模式匹配（Boogie 级）：

- 在同一 procedure 内识别形如：
  - `x := add.bvW(x, 1bvW); ... call reg.write(idx, x);`
  - 或 `call reg.write(idx, add.bvW(y, 1bvW));`
- 并要求：
  - `reg` 是目标寄存器数组（来自性质/配置）
  - `idx` 是目标槽位（来自投影或用户指定）

识别成功后，在该 `reg.write` 前后插入 `did_target_inc_this_step := true`。

> 备注：这是 v0 最关键的工程点；它决定“pump loop”是不是你想要的那种 loop。

### 4.3 阶段 B：加速到 `Pre(wraparound)` 并在全语义下一步触发（或排除）违规

阶段 A 找到泵循环后，我们构造一个“加速版模型”：

#### 4.3.1 加速转移（existential k，over-approx；配套确证）

在满足泵投影 guard 的地方插入：

- `havoc k: bvW; assume k != 0bvW;`
- `seq := add.bvW(seq, k);`（对目标槽位；必要时对跨节点副本一起加速，取决于泵循环含义）
- `assume seq == MAXbvW;`（把状态带到临界前沿）

然后继续执行 1~2 个 full step（不再加速），看是否出现：

- `MAX -> 0` 的翻转写回
- 以及你关心的单调性断言被违反

这里“很快”的原因：加速把 `2^w` 的深度变成一次求解（`k` 的存在见证）。

#### 4.3.2 结果解释

- 如果加速版能迅速找到违反单调性的反例：说明“在抽象假设下”翻转确实可导致违规。
- 如果加速版证明 SAFE（或找不到）：说明要么翻转不会导致该性质违规，要么需要更强环境/调度/投影精化才能触发。

### 4.4 阶段 C：确证（消除伪加速带来的伪反例）

加速是 over-approx，因此必须确证：

1) 用原模型（无加速）+ 更强输入收紧（你的 `.prop` 已经在做）复跑；
2) 如果仍难以从 0 跑到翻转点，则至少做两种确证：
   - **循环可重复性确证**：在原模型中强制执行“泵循环段”两次，检查投影确实回到同一类、且隐藏状态未破坏（可用额外断言/ghost 检测）。
   - **位宽缩放 sanity**：把 `bv16` 缩为 `bv8`（若你们工具链允许），验证“同构 bug”在小位宽下确实可达（趋势验证）。

> v0 的目标是：先证明“这套管线能在实践中把 hours 级问题变成 minutes 级”。严格的完全确证/证明属于 v2 的研究工作量。

---

## 5. v1 自动化：把管线塞进 Ultimate toolchain（插件化）

### 5.1 为什么需要 v1

v0 外部编排能验证可行性，但要做系统性实验与长期维护，需要把关键步骤“产品化”：

- 自动识别目标寄存器与 +1 写回点
- 自动生成 pump-probe / accel / confirm 三份模型
- 自动解析 witness 并迭代精化投影（CEGAR）

### 5.2 插件插入点（两条路线）

**路线 A（Boogie→Boogie 源码级改写插件）**

- 插在 `boogie.preprocessor` 后、`rcfgbuilder` 前
- 优点：实现简单，直接生成/修改 Boogie AST

**路线 B（ICFG/RCFG 级变换插件）**

- 插在 `rcfgbuilder` 后、`traceabstraction` 前（或走 `icfgtransformation`）
- 优点：更适合做 SCC/loop 分析，插入 summary edge（加速边）

仓库已有 ICFG transformation toolchain 示例：

- `ultimate/trunk/examples/toolchains/IcfgTransformer.xml`（包含 `de.uni_freiburg.informatik.ultimate.plugins.icfgtransformation`）

v1 推荐路线 A：先把工程闭环跑通，再考虑路线 B 的“更语义化 summary edge”。

### 5.3 v1 插件的最小功能清单（MVP）

1) 从 Boogie 中识别：
   - 目标寄存器数组名（从断言/配置读）
   - 目标槽位 index（从 spec/global assume 或默认 0）
   - “+1 写回点”（Boogie 模式匹配）
2) 注入 pump-probe 插桩（§4.2）
3) 生成加速版插桩（§4.3）
4) 提供投影的 CEGAR 精化接口：
   - 初始投影 = 默认最小集
   - 若加速反例无法确证 → 把 witness 中变化但未纳入投影的变量加入投影，重跑

### 5.4 v1 的输出工件（便于实验/论文）

- pump witness：循环长度、投影、+1 写回点位置
- accel witness：翻转前沿 + 下一步违规轨迹
- confirm 结果：是否可确证（UNSAFE/伪反例/UNKNOWN）
- 统计：每阶段用时、CEGAR 迭代次数、投影变量数增长曲线

---

## 6. 具体实现计划（下一步开始动手）

> 这里按“先跑 v0 可行性，再做 v1 插件化”列出可执行 TODO。

### 6.1 v0（1~2 周内目标）

v0 在本仓库已经落地成“外部编排 + Boogie→Boogie 变换”的工作流（避免污染 `dslc/backends/boogie.py`，保持单一职责）：

1) `dslc/transform/wraparound.py`：生成 `closure_check/confirm` 等阶段的变换版 `.bpl`
2) `Procurator/argo/code/spec/prop_compile/run_wraparound.py`：外部编排脚本（按阶段生成 `.bpl` + 跑 Ultimate）
3) Netchain（`Procurator/argo/code/spec/bench/netchain_bug_s1s2.prop`）作为最小可复现实验：在 minutes 级触发翻转反例

### 6.2 v1（2~6 周内目标）

1) 把 v0 的“Boogie 插桩生成”拆成可复用模块（保持单一职责）：
   - `wraparound_analysis.py`：识别 +1 写回点（Boogie 文本/AST）
   - `wraparound_instrument.py`：注入 pump-probe/accel 插桩
2) 选择路线 A（Boogie→Boogie）做 Ultimate 插件原型：
   - 插入点：`boogie.preprocessor` 后
   - 功能：自动注入 pump-probe/accel（MVP）
3) 新建一个 toolchain XML（例如 `Procurator/argo/code/spec/config/ReachSafety-WrapAccel.xml`）：
   - 在 `boogie.preprocessor` 与 `rcfgbuilder` 之间插入你的新插件
4) 形成端到端命令：
   - `Ultimate -tc ReachSafety-WrapAccel.xml -s <GemCutter.epf> -i <bpl>`

---

## 7. 风险与回退策略

- **风险：投影选得太小导致伪反例多**
  - 回退：把投影精化做成 CEGAR；默认从小开始，伪反例触发扩投影
- **风险：+1 写回点识别不完整**
  - 回退：允许用户在 spec 中显式标注目标写回点/寄存器（先跑通，再自动识别）
- **风险：需要 LTLAutomizer，但缺少 ltl2ba**
  - 回退：v0 先用 safety 编码；若后续要试 lasso/witness 形式，再补 `ltl2ba` 依赖

---

## 8. 与当前仓库代码的结合点（指路）

- Boogie harness/插桩生成：`dslc/backends/boogie.py`
- 一键跑 Ultimate：`Procurator/argo/code/spec/prop_compile/run_gemcutter.py`
- 现成 reachability toolchain：`ultimate/trunk/examples/concurrent/bpl/regression/ReachSafety.xml`
- 现成 LTL toolchain（可选）：`ultimate/trunk/examples/toolchains/LTLAutomizer.xml`
- PDR/Sifa/CHC 作为备选：`ultimate/trunk/examples/programs/regression/bpl/PdrAutomizerBpl.epf`、`ultimate/trunk/examples/toolchains/Sifa.xml`、`ultimate/trunk/examples/toolchains/BoogieToChcToTreeAutomizer.xml`
- Netchain 的 V0-1 落地附录（closure pump 证明支撑 `Pre(wraparound)`）：`doc/ultimate_wraparound_v0_1_netchain.md`

---

## 9. v1（完整版本）设计：P4B 依赖分析 + 单调性筛选 + 闭包泵证明 + 加速确证

> 目标：把目前 “Netchain 专用能跑通” 的 V0-1 提升为一个**可系统化应用于多种分布式 P4 系统**的版本：能自动发现哪些寄存器可能发生“翻转类深 bug”，并在 **soundness guard** 下进行闭包泵证明与加速确证，形成可复用产物（witness + proof artifact）。

### 9.1 总体管线（用户视角）

输入：

- P4 程序 + 控制面表项 + 拓扑/部署
- `.prop` 性质 + 环境收紧（你们 DSL）

输出：

- `UNSAFE`：witness（GraphML）+ 关键寄存器/槽位/翻转点 + 可重放的“包序列/事件序列”约束
- `SAFE/UNKNOWN`：阶段性诊断（候选寄存器列表、闭包证明是否成功、失败原因）

核心阶段：

1) **Property-driven candidates**：用 P4B（meta + slicing）找出“影响性质的寄存器/槽位”，并做 counter-like/单调性筛选。
2) **Closure pump proof**：对每个候选，证明存在一个可重复的“泵循环/轮次（round）”：
   - 轮次执行 1 次净效应为 `reg[idx] := reg[idx] + 1 (mod 2^w)`
   - 投影状态 `proj(s)` 闭包：执行完轮次后回到同一等价类，且下一轮仍然可重复（闭包/可重复性）
3) **Accelerated confirm**：在通过闭包 guard 的前提下，把 `reg[idx]` 快进到 `MAX`（或 `MAX-1`），再用**全语义**快速验证翻转是否触发性质违反。

> 备注：这里的“等价类划分”就是 `proj(s)`；闭包证明的本质是在证明 `proj` 上的归纳不变性 + 目标寄存器的进度（progress）。

### 9.2 关键定义（工程可落地）

把一个分布式 P4 系统在 Boogie harness 下抽象为：

- 状态 `s`：所有节点寄存器数组、全局变量、队列计数、关键 meta 等
- 单步 `Step(s, i) -> s'`：执行一个 pass（或一个调度选择下的 pipeline 片段）
- 轮次 `Round`：一个固定的 step 序列（通常来自你们 deterministic scheduler 的一个 phase 周期），可看作 loop body

我们要证明的闭包泵性质（对某个寄存器 `R[idx]`）是一个 Hoare triple：

`{ C(s) }  Round  { C(s') ∧ R'[idx] = R[idx] + 1 (mod 2^w) }`

其中：

- `C(s)`：闭包条件（把“能进入泵循环且能重复执行”的必要条件写出来）
- `proj(s)`：等价类投影（`C` 通常编码为 `proj(s)` 的域约束 + 轮次前后 `proj` 相等）

### 9.3 候选寄存器筛选（P4B + 单调性）

V1 的核心是让“闭包泵证明”只跑在少量真正相关的寄存器上。

#### 9.3.1 从性质出发的依赖分析（P4B slicing）

1) 从 `.prop` 的 global asserts/关系断言中提取 seed（涉及的状态变量）
2) 用 P4B 的 slicing（或你们已有的 seed-driven slicing）把：
   - 与 seed 无关的寄存器/元数据/表项逻辑剪掉
   - env 的 `havoc` 也同步剪到仅影响 slice 的字段

产物：

- `relevant_registers`: 只保留会影响性质的寄存器对象集合
- `relevant_inputs`: 会影响这些寄存器与性质的输入字段集合

> 这一步的目标是把 “DistCache 里成百上千的计数器/索引” 缩到“性质相关的几十个以内”。

#### 9.3.2 counter-like（单调性）语法筛选（Boogie 级，保守但便宜）

在 slice 后的 Boogie 里对每个 `reg.write(idx, expr)` 做模式匹配，识别：

- `expr == add.bvW(reg.read(idx), 1bvW)`（最优先：典型 wraparound counter）
- `expr == add.bvW(reg.read(idx), cbvW)`（次优：步长为常数）
- `expr == reg.read(idx)`（无效写，可忽略）

并记录：

- 候选寄存器对象 `R`、位宽 `W`、槽位表达式 `idx`
- 更新步长 `delta`（通常是 `1`）
- 该写点所在的 action/table/控制流位置（供闭包投影选择）

> 这一步是“过滤器”而不是证明：它只做 cheap 的 syntactic screening，把明显不是计数器的寄存器丢掉。

### 9.4 自动构造闭包条件 C(s) 与投影 proj(s)

#### 9.4.1 投影的起点：最小集合（可闭合优先）

`proj` 初始只包含三类信息：

1) **能决定泵循环是否执行**的 guard 变量：
   - role/mode、表命中（hit）、分支条件涉及的 meta/hdr 字段
2) **能决定“写到哪个槽位”**的 index 相关变量：
   - `idx` 的常量/表达式用到的字段（key/hash/显式 index）
3) **会影响下一轮调度/可重复性**的系统级变量：
   - `procurator_phase`（或你们的调度相位变量）
   - inbox/queue 计数（简化版即可：只对会影响“是否有包可处理”的计数入投影）

#### 9.4.2 投影精化：CEGAR 风格扩充（避免伪泵）

闭包证明失败/出现伪加速反例时，按 witness 自动扩充投影：

- 找 witness 中在轮次前后发生变化、且出现在：
  - 泵 guard / idx / 性质断言 的 backward slice 上的变量
- 把这些变量加入 `proj`，重跑闭包证明

这一步是实现“既不太大、又不太小”的关键机制。

### 9.5 闭包泵证明（Closure Check）的两部分

为了避免“伪泵”（你之前担心的：看似能 +1，但实际上泵不可重复/会停），V1 把闭包证明拆成两个可验证目标：

1) **Progress**：每轮确实发生目标更新（不会因为分支/guard 停止）
   - 证明 `Round` 内一定执行到目标 `reg.write`，且写入值满足 `+delta`
2) **Closure**：执行完 `Round` 后，保持 `proj` 不变，并且下一轮的 guard 仍成立（从而可无限重复）

产物：

- `closure_check.bpl`：一个 loop-free 或 “单轮次 + assert” 的证明任务（尽量让 Ultimate 在 minutes 内给 SAFE）
- 失败诊断：哪条 guard 不闭合/哪变量破坏可重复性

> 你们当前实现的 `closure_check` 可以视为这个思想的 V0-1 特化；V1 要把它参数化为“任意候选寄存器/任意投影集”。

### 9.6 Reachability：从初态进入闭包集合 C(s)

闭包证明只说明“进了循环就能一直泵”，但还需要证明“能进”：

- `entry_check`: 在原模型（全语义/同 env 收紧）中找一个可达状态 `s0` 使得 `C(s0)` 成立
- witness extraction: 从 GraphML 抽出 `proj(s0)` 的具体赋值（作为后续加速/确证的锚点）

这一步让整个流程从“启发式快进”提升到“有 reachability 证据的快进”（更接近 sound）。

### 9.7 加速确证（Accelerated Confirm）

当 `entry_check` 与 `closure_check` 都通过后，我们可以构造一个**可达性等价**的快进：

- 令 `R[idx]` 直接设置到 `target ∈ {MAX, MAX-1, ...}`
- 保持 `proj` 的赋值为 witness 中的 `proj(s0)`
- 然后在全语义 harness 下跑很短后缀，检查是否触发翻转违规

并输出：

- UNSAFE witness（bug 反例）
- 一份 “proof artifact”：说明快进是由 `entry_check + closure_check` 支撑的（可写进论文的能力边界/条件）

### 9.8 工程落点：代码模块与职责划分（保持单一职责）

建议的模块分层（与当前仓库现状兼容）：

- `P4B-Translator/`：只负责 P4→Boogie 与 slicing/meta（不做 wraparound 专用逻辑）
- `dslc/compiler.py`：编译 `.prop`→base `.bpl`，并暴露“是否 slicing”一键开关
- 新增 `dslc/analysis/`（只做分析，不改语义）：
  - `deps.py`: seed→依赖闭包（基于 P4B meta 或 Boogie AST）
  - `register_updates.py`: 扫描 `reg.read/write`，提取候选 `(+delta)` 写点与 idx
  - `projection_cegar.py`: witness→投影精化策略
- `dslc/transform/wraparound.py`：只做 Boogie→Boogie 语义保持的插桩/变换（closure_check/confirm/…）
- `Procurator/argo/code/spec/prop_compile/run_wraparound.py`：外部编排与实验脚本（批量跑、多候选并行、产物整理）

### 9.9 里程碑（建议）

- **V1.0（两周）**：自动从性质 slice 中找候选寄存器 + 生成参数化 `closure_check`，在 Netchain + 另一个系统上复现 wraparound bug（minutes 级）
- **V1.1（四周）**：加入 `entry_check + witness extraction`，形成“带 reachability 证据的快进”，减少伪加速
- **V1.2（六周）**：对 DistCache 类“多寄存器/多槽位”做批处理与汇总报告（候选排序、失败原因分类、成功触发的 bug 列表）

### 9.10 “完整 sound”需要什么（以及为什么我们说目前只是接近 sound）

这里的“sound”必须先说清楚 **相对于什么语义**：

- 若你的 Boogie harness 本身做了抽象（例如 Bag 队列、有限容量、简化 extern/target 语义、收紧 env 输入空间），那么任何“soundness”首先都是 **相对于该模型**，而不是相对于真实交换机/网络实现。
- 其次还要区分两类常见目标：
  - **UNSAFE soundness（无伪反例）**：报告的 bug witness 在原模型里确实可达。
  - **SAFE soundness（无漏报/可证明正确）**：报告 SAFE 意味着在原模型里确实不可能违规（这通常更难）。

你质疑“目前只是接近 sound”，核心就是：我们在加速/快进里引入了一个“非原语义步骤”，如果它没有被证明为 reachability 等价（或至少是 under-approx），就可能产生伪反例。

#### 9.10.1 让 `closure_check → confirm` 对 UNSAFE 变成“完全 sound”的最低条件

要做到“发现的翻转反例一定是真实可达的”，至少要有三份可检查的证据（proof artifacts）：

1) **Entry 可达性证据（`entry_check`）**
   - 在 *原模型*（无加速）下，找一个具体可达状态 `s0`，使闭包条件 `C(s0)` 成立。
   - 产物：witness（GraphML）+ 关键变量赋值（`proj(s0)` 及必要的 frame 变量）。

2) **闭包/进度证据（`closure_check`）**
   - 证明对所有满足 `C(s)` 的状态，执行一个 Round 后：
     - 仍满足 `C(s')`（closure：下一轮仍可执行）
     - 目标寄存器槽位满足净效应 `R'[idx] = R[idx] + delta (mod 2^w)`（progress）
     - 以及必要的 **frame 条件**（哪些非目标变量保持不变 / 或至少保持在 `C` 允许的集合内）
   - 这一步证明的是“泵不是伪的”：它不只是“存在一次 +1”，而是“可重复 + 每轮都有进度”。

3) **k 次迭代可达性推导（加速合理性）**
   - 一旦 (2) 成立，`k` 次迭代到达边界值是一个数学推导（可被单独检查）：
     - 若 `delta=1`，则总能到达 `MAX`（对 bitvector 模加）
     - 若 `delta≠1`，则需要 `gcd(delta, 2^w)` 的可达性判定（只能到达某个同余类）
   - 产物：把 `k` 的取值与目标 `MAX/MAX-1` 的关系记录下来（可在论文里作为“可达性证据的一部分”）。

满足上述 1)+2)+3) 后，`confirm` 里的“快进到 MAX”不再是启发式，而是一个有证据支撑的 summary（即：存在一条真实执行等价于“跑 k 轮然后到达同样的边界状态”）。

#### 9.10.2 SAFE 怎么办：退化到 Ultimate 原生证明；本方案只承诺 UNSAFE soundness

你说得对：本方案的工程目标是 **加速找“翻转类深反例”**，并把 `UNSAFE` 做到严谨（无伪反例）。

因此我们建议把结论拆开承诺：

- **UNSAFE（我们要严谨承诺）**：只有当 `entry_check` 与 `closure_check` 都通过，并且 `confirm` 给出违反 witness 时，我们才输出“certified UNSAFE”。此时的 `UNSAFE` 在你们的模型/假设下是 sound 的（证据链见 9.10.1）。
- **SAFE（不在 wraparound 管线里做承诺）**：如果你需要证明 SAFE，就直接对 *原模型* 运行 Ultimate/GemCutter/Automizer 的原生证明流程（不启用任何快进/加速变换）。wraparound 管线的职责不是给出 SAFE 证明，而是给出 *sound UNSAFE* 与诊断信息。

换句话说：wraparound 管线是一个 **bug-finding accelerator**；它不追求完备性（可能漏 bug），但追求“报 bug 必真”（在模型/假设下）。
