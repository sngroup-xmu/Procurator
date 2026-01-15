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

1) 在 `dslc/backends/boogie.py` 增加一个“wraparound 研究模式”（先不暴露太多开关）
   - 生成 `pump-probe.bpl`：插入 §4.2 的 ghost 变量与断言
   - 生成 `accel.bpl`：插入 §4.3 的加速块
2) 在 `Procurator/argo/code/spec/prop_compile/` 增加一个外部编排脚本（例如 `run_wraparound.py`）：
   - step A：编译 pump-probe 并跑 Ultimate（ReachSafety.xml + 现有 GemCutter settings）
   - step B：根据 witness/手工配置生成 accel 版本并跑
   - step C：触发 confirm 跑（默认 `--no-prune` + 更强 env）
3) 在 Netchain（`netchain_bug_s1s2.prop`）上验证：
   - pump-probe 能否在很短时间内找到 loop（预期：能）
   - accel 能否比原始从 0 起跑显著更快找到翻转违规（预期：能）

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
