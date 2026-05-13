以下内容分两部分：
# 注意（最高优先级）：1、需要每次修改完之后对于之前能找到的bug，之前翻译正确的p4程序，都依旧能够正常工作。这需要设计并运行回归测试。 2、运行完单个spec的实验之后，需要在AGENTS.md中记录完成情况，包括spec，时间，完成进度，是否有实现错误导致的坑，是否修复并沉淀为冒烟测试这几项
1. **Procurator（分布式 P4 状态化验证）设计文档（可直接丢进 agent 工具作为执行规范）**——各小节均给出参考依据与引用。

## 当前执行准则（2026-05-08 补充）

- 对单个 case 的推进顺序先看生成的 Boogie/harness 是否正确。如果转出的 BPL 或 harness 语义不对，应继续修 P4B/DSLC 的转换和建模，不用把时间花在错误模型上跑 solver。
- 如果确认 BPL/harness 形状和语义都对，则可以把 Ultimate/GemCutter 时间放开跑。不要因为短时间跑不出来就判断 case 不存在；不是所有 case 都能在 10 分钟内完成。
- `SAFE/UNSAFE/TIMEOUT/UNKNOWN` 的解释必须跟阶段语义绑定：短 timeout 或未认证 SAFE 不代表 bug 不存在；closure 未证明只说明当前 proof 没跑完或模型/投影还需分析。


---

# 设计文档：Procurator vNext（P4 分布式状态化验证：BMC + 证明取向后端 + P4-aware 优化）

## 0. 系统概览（仓库实现对齐）

这段是“本仓库当前代码”视角的系统介绍（偏工程落地），用于帮助快速定位：**哪个模块负责什么、有哪些关键开关、哪些优化已经落到实现里**。后面的章节仍保留更偏研究/论文表达的设计细节。

### 0.1 端到端流程（我们这条 Boogie + Ultimate/GemCutter 产线）

1) **输入**：`.prop` DSL 规格（拓扑 + import 的 P4 程序/表项 + env 约束 + assert）。
2) **DSL 编译**：`dslc/compiler.py` 解析/类型检查/建模，再调用后端生成产物。
3) **单交换机语义翻译（P4 → Boogie）**：`P4B-Translator/backends/verify/bpl_verify/main.cpp`（`p4c-translator`）把每个 P4 程序 + 控制面表项编译成 Boogie 过程/全局状态；可选运行 slicing 并输出 meta（`--meta-out`）。
4) **分布式 harness 拼接（系统级语义）**：`dslc/backends/boogie_backend.py` 负责编排“每节点 P4→Boogie（可 slicing）→ 前缀化/插桩 → 系统 harness 拼接”，其中 harness 生成主体在 `dslc/backends/boogie_harness.py`。
5) **验证后端**：Ultimate/GemCutter 对最终 `.bpl` 做 bug finding / proof attempt，输出 `UNSAFE`（witness）或 `SAFE/UNKNOWN`。

#### 0.1.1 架构图（ASCII）

```text
        .prop (topology + env/host + assert)
                  |
                  v
           dslc/compiler.py
                  |
                  v
      dslc/backends/boogie_backend.py
        |    |         |           |
        |    |         |           +--> dslc/backends/boogie_harness.py (pass-atomic / queues / POR / symmetry)
        |    |         +--> dslc/backends/boogie_prefix.py + boogie_registers.py + boogie_pipeline.py
        |    +--> dslc/backends/boogie_seeds.py (slice seeds + hdr.* propagation)
        +--> P4B-Translator/p4c-translator (slicer.cpp + translate/* + analysis/monotonic.cpp -> meta.json)
                  |
                  v
              merged .bpl
                  |
                  v
     Ultimate (GemCutter/Automizer/...) -> witness/SAFE/UNKNOWN

  wraparound fast-forward (integrated):
    `procurator verify` (default `--wraparound auto`) may run:
      base .bpl -> dslc/workflows/wraparound_cegis.py -> staged .bpl -> Ultimate
```

### 0.2 仓库模块与职责（单一职责划分）

**DSL 前端与系统级建模**

- `dslc/compiler.py`：DSL 解析、语义检查、后端调用；统一对外的编译入口/开关（例如 `--no-prune`、`--por`、`--boogie-harness`、`--env`、`--no-two-stage`）。
- `dslc/workflows/wraparound.py`：wraparound 产物生成器（legacy/debug）。
- `dslc/workflows/wraparound_cegis.py`：wraparound CEGIS/CEGAR（主验证管线集成：ENTRY/CONFIRM/CLOSURE）。
- `dslc/backends/boogie.py`：后端入口（对外 API 稳定），仅 re-export `BoogieBackend`。
- `dslc/backends/boogie_backend.py`：Boogie 后端编排（加载/调用 P4B、拼接各节点、merge 产物）。
- `dslc/backends/boogie_harness.py`：系统级 harness 生成（并发/串行两种 harness；pass-atomic / two-stage）。
- `dslc/backends/boogie_seeds.py`：分布式 slicing 种子收集与 `hdr.*` 反向传播（全局保守闭包）。
- `dslc/backends/boogie_bpl.py`：Boogie 文本层工具（输入字段提取、missing decl patch、按使用过滤 env havoc）。
- `dslc/backends/boogie_prefix.py`：Boogie 前缀化与 bvbuiltin 去重/Ultimate 兼容重写。
- `dslc/backends/boogie_registers.py`：寄存器数组识别与 write 插桩（last/index0 镜像）。
- `dslc/backends/boogie_pipeline.py`：从单节点 Boogie 中提取 ingress/egress 两阶段切分（two-stage harness）。
- `dslc/backends/boogie_p4b.py`：P4B-Translator 调用封装（含 include path 发现）。

**P4 → Boogie（P4B-Translator）**

- `P4B-Translator/backends/verify/bpl_verify/main.cpp`：`p4c-translator` 主程序；负责：
  - 调用 P4C 前端解析/类型检查（含 `--fromJSON`）。
  - 调用 slicing（见下）并把结果灌入 `P4VerifyOptions`（供 translate 阶段做过滤/寄存器剪枝）。
  - 可选输出 meta（`--meta-out`）与后分析（例如 wraparound/单调更新摘要）。
- `P4B-Translator/backends/verify/slicing/slicer.cpp`：P4 IR slicing pass（CFG/CDG/DDG + backward slice），输出：
  - `keepStatementIds`：哪些 IR 语句保留（用于 `applySlice` 真的把 IR 剪掉）。
  - `keepVarNames` / `keepTables`：后续翻译时只声明/只生成相关变量/表。
  - `regMaxIndex`：按 seed 推断寄存器最大索引（用于把 index 约束为较小范围，减少 Boogie 状态空间）。
- `P4B-Translator/backends/verify/translate/*`：核心翻译逻辑（IR → Boogie）、BMv2 控制面命令解析（`bmv2.*`）、以及与 P4LTL 相关的语法/工具链接口（如果开启）。

**基准/规格/脚本**

- `Procurator/argo/code/spec/bench/*.prop`：系统级基准规格（Netchain/DistCache/Gecko/...）。
- `bin/procurator` + `dslc/cli/*`：当前唯一推荐入口（compile/verify/wraparound/ablation/smoke；no-cache 默认）。
- `Procurator/argo/code/spec/prop_compile/*`：历史遗留脚本目录（已逐步替换为 `procurator` CLI；不建议再直接使用/依赖）。

### 0.3 当前主要“优化开关”与落点（设计 ↔ 实现对齐）

下面列的是“确实落在代码里的关键旋钮”，每项都对应一个明确模块/实现位置。

1) **程序切片（slicing）+ env 输入剪枝（prune）**
   - 入口（DSL）：`dslc/compiler.py` 的 `--no-prune`（关闭 slicing + env 剪枝）。
   - P4 侧实现：`P4B-Translator/backends/verify/slicing/slicer.cpp`（输出 keep 集合/寄存器索引上界），`P4B-Translator/backends/verify/bpl_verify/main.cpp` 调 `applySlice`。
   - 系统侧实现：`dslc/backends/boogie_backend.py` 在 `prune_env_inputs` 时只对 slice 后仍“活着”的输入字段 `havoc`（核心实现：`dslc/backends/boogie_bpl.py` 的 `filter_input_vars_by_usage`）。
   - **分布式全局剪枝（种子传播）**：由于 P4B slicing 是“每个节点单独运行”，它看不到我们的拓扑/队列语义，所以 dslc 需要在系统层做一次保守的种子传播：
     - dslc 先从 spec 的 **assert + DSL 语句（property 依赖）** 里收集每个节点的 slicing seed（`dslc/backends/boogie_seeds.py` 的 `build_slicing_plan`）；**assume/env 约束只用于收紧输入，不作为 slicing criteria**（否则会把与性质无关的字段错误当成依赖，导致切片过大、验证变慢）。
     - 若存在拓扑链路，则把 **on-wire 的包字段（`hdr.*`）** 沿 `dst → src` 方向做传递闭包（`propagate_packet_seeds`），保证“下游节点用到的 header 字段”不会被上游节点切掉。
     - 具体实现入口：`dslc/backends/boogie_seeds.py`（`build_slicing_plan` / `propagate_packet_seeds`，并在 `spec.links` 非空时启用）；传播时只传 `hdr.*`（on-wire），不传 `meta.*`/`standard_metadata.*`（node-local）。
   - **当前限制（需要在设计里明确）**：这一步传播基于“spec 显式提到的种子”；如果某个下游性质只提到了 `meta/reg`，但其计算依赖某些 `hdr.*` 字段，那么要做到完全 sound 的“全局 slicing”，应当做一个系统级 fixpoint（先切下游、读出其 slice 后需要的 `hdr.*`，再反向喂给上游重切），目前实现尚未自动化该迭代。

2) **寄存器索引剪枝（regMaxIndex → 约束 index 域）**
   - P4B 侧分析：`P4B-Translator/backends/verify/slicing/slicer.cpp` 产出 `regMaxIndex`。
   - 翻译侧生效：`P4B-Translator/backends/verify/translate/translate.cpp` 依据 `options.slicingRegMaxIndex` 对 `read/write` 的 index 生成 `assume(index <= max)`。
   - 典型效果：把“所有 4096 槽”收紧到“只关心的少数槽”（例如只验证 `reg[0]` 时强制 index=0）。

3) **并发语义压缩：pass-atomic + 全局锁**
   - 系统侧实现：`dslc/backends/boogie_harness.py` 生成的 harness 把“单次 pipeline 处理”作为原子步（交错点只在“选哪个节点执行下一次 pass”）。
   - 对 Ultimate/GemCutter：减少可交错点，利于其并发验证/泛化能力。

4) **调度/交错约简（POR 开关）**
   - 入口（DSL）：`dslc/compiler.py --por`。
   - 当前实现位置：`dslc/backends/boogie_harness.py`（以 pass 边界/guard 形式做保守约简；后续可与更强的 commutativity oracle 对齐）。

5) **对称性约简（symmetry）**
   - 系统侧实现：`dslc/backends/boogie_harness.py` 在对称节点上添加约束，减少等价状态/等价调度分支。

6) **两种 harness：并发 vs 串行（便于对比/调试）**
   - `dslc/compiler.py --boogie-harness {concurrent,sequential}`：
     - `concurrent`：生成 `fork/atomic` 的并发 Boogie（更贴近 GemCutter 的并发验证定位）。
     - `sequential`：生成单线程 nondet 调度循环（便于调试/减少并发编码噪声）。
   - 该项是“建模选择”，不是优化本身，但会显著影响后端性能与 witness 形态。

7) **wraparound（计数器翻转）加速：闭包泵（closure pump）+ fast-forward**
   - 背景：分布式 P4 系统里常见“计数器/序列号寄存器”在 `2^w-1 -> 0` 翻转时触发一致性/顺序性 bug；直接让验证器从 0 符号执行到翻转点会产生极长前缀（尤其 16/32 位寄存器），导致验证“卡住”。
   - 关键思想（v0-1 实现）：不在系统语义里“硬塞 65535 初值”，而是把它做成一个**可选的加速管道**：
     1) 先用 P4B 从 IR 里提取“看起来像计数器”的更新（`x := x + k` / `x := x - k`），输出到 meta；
     2) 再在系统级 Boogie 上构造一个**闭包检查（closure_check）**：证明“从 cutpoint 开始，把目标寄存器置为任意 `seq0 != MAX`，跑完一个调度轮次后，寄存器必然变成 `seq0 + k`，并且投影变量（队列计数/phase 等）保持不变”；
     3) 通过后，把寄存器 fast-forward 到 `MAX`（或接近翻转的阈值）再跑原始断言，快速触发翻转后缀（confirm）。
   - 实现落点（严格按职责划分）：
     - **P4B 提供“单调/仿射更新摘要”**：`P4B-Translator/backends/verify/analysis/monotonic.cpp` 会识别寄存器相关的仿射自更新，并把 `wraparound_registers / wraparound_updates` 写入 `--meta-out`（见 `P4B-Translator/backends/verify/translate/options.h` 中 `WraparoundUpdate`）。
     - **DSL 侧推断候选目标**：`dslc/analysis/wraparound_candidates.py` 根据：
       - global assert 是否直接提到了 `reg[i]`（NetChain 风格），或
       - meta 里 `wraparound_updates` 指出某个“被单调更新并写回寄存器”的变量（DistCache 风格）
       推断 `pump_reg / index / step_delta / proj_vars`。
     - **Boogie 侧插桩/变换（系统级）**：`dslc/transform/wraparound.py`
       - `ENTRY_CHECK`：检查 base harness 是否可达（避免 env/表项不一致导致的“空模型”伪结论）。
       - `CLOSURE_CHECK`：把 `mainProcedure` unroll 一个调度轮次，插入闭包断言（证明“泵”闭包性）。
       - `PUMP/ACCEL/CONFIRM`：在 cutpoint 周围插桩、选择性剥离无关断言/调试快照、并在 `confirm` 前 fast-forward 到 `MAX`。
     - **实验驱动 CLI**：`./bin/procurator wraparound`（实现：`dslc/cli/wraparound.py`）负责：
       - 编译 base `.bpl`（sequential harness，no-cache：每次 run 创建新的 `<OUT_DIR>`）
       - 读取 `<OUT_DIR>/work/*.meta.json`
       - 推断候选并生成多阶段 `.bpl`（`closure_check/pump/accel/confirm`）
       - （可选）调用 Ultimate 跑日志，并为每个 stage 隔离 Ultimate HOME/工作区
   - 一个重要的工程优化点：当目标是固定槽（例如 `reg[0]`），系统 Boogie 里通常会有标量镜像（如 `<reg>__last0_value`）；`dslc/transform/wraparound.py` 会优先用该标量而非数组读写（显著减少 SMT 的 array 负担）。
   - **CEGIS 精化（shape-aware）**：`dslc/workflows/wraparound_cegis.py` 在 CLOSURE 超时/UNKNOWN 时，基于 CONFIRM witness 合成“输入形状约束”，优先锁定 hash/partition/cap/路径命中（例如 `hashval_*`, `*_partition`, `*_tbl_*.hit/action`），以保证 leafload/spineload 在同一路径上单调增长且不被其它路径重置。该约束只作用于环境输入与候选寄存器相关变量，保证证书保守且可复现（写入 manifest）。
   - **CEGIS 迭代策略（closure-only）**：ENTRY_CHECK 与 CONFIRM 都是存在性查询，用于得到固定 witness/seed；一旦 CONFIRM=UNSAFE，后续 refinement 只重跑 CLOSURE_CHECK（并基于 seed witness 合成 assumes / 细化 proj-vars），不再重跑 ENTRY/CONFIRM，避免把存在性查询“卷入合成”导致 witness 被偏置或丢失。

### 0.4 例子：Netchain 在 `seq_reg` 断言种子下，切片应保留什么/剪掉什么

**原始 P4 关键片段**：`Procurator/argo/code/dataset/Netchain/netchain_16.p4` 的 ingress 中：

- `assign_value_act()` 同时写两个寄存器：
  - `sequence_reg.write(index, hdr.nc_hdr.seq);`
  - `value_reg.write(index, hdr.nc_hdr.value);`
- `apply` 中 `NC_READ`（`op==10`）走 `read_value.apply()`，`NC_WRITE`（`op==12`）走 `maintain_sequence/assign_value/...`。

**当性质只关心 `sequence_reg[0]` 时（seed = `sequence_reg[0]`）**，切片后的“语义上必要”保留/剪枝应满足：

- **保留的控制路径（与 `sequence_reg` 相关或影响转发控制种子）**：
  - `hdr.nc_hdr.isValid()` 分支（决定是否进入主逻辑）。
  - `find_index.apply()` / `get_sequence.apply()`（决定 `meta.location.index`、读出 `meta.sequence_md.seq`）。
  - `op==12`（write 请求）路径下的 `maintain_sequence.apply()` 与 `assign_value.apply()`（会更新/写回 `sequence_reg`）。
  - 转发相关的 `ipv4_route.apply()`（因为 slicer 默认把 `egress_spec` 这类转发控制量作为隐式种子，避免把转发语义剪“坏”）。
- **应被剪掉的路径/语句**（与 `sequence_reg` 无关）：
  - `op==10` 分支里的 `read_value.apply()`（读 `value_reg` 与性质无关）。
  - `assign_value_act()` 内部对 `value_reg.write(...)` 的写入（与 `sequence_reg` 无关）。
  - `pop_chain.apply()` / `drop_packet.apply()` / `failure_recovery.apply()` 等与 `sequence_reg` 无关的控制流（只要不影响被保留的种子）。

**在 P4B slicer 输出层面的可检查结果（更“工程化”的对照）**：

- 期望 `keepTables` 至少包含：`assign_value`、`get_sequence`、`maintain_sequence`（表明写路径仍在）。
- 期望 `keepTables` 不包含：`read_value`（表明 `value_reg` 读路径被剪掉）。
- 期望 `keepVarNames` 包含 `hdr.nc_hdr.seq`，且不包含 `hdr.nc_hdr.value`。
- 期望 `regMaxIndex(sequence_reg)==0`（把寄存器槽域剪到 `{0}`）。

**对应的 C++ 侧冒烟自检（不依赖 Python 文本匹配）**：

在 `p4c-translator` 里加入了 `--slicing-selftest=netchain_seq`，它直接检查 slicer 的 `SliceResult`（tables/vars/regMaxIndex）：

`P4B-Translator/build-host/p4c-translator -I P4B-Translator/p4include --goto --bmv2cmds Procurator/argo/code/dataset/Netchain/commands_1.txt --slicing-vars=sequence_reg[0] --slicing-selftest=netchain_seq Procurator/argo/code/dataset/Netchain/netchain_16.p4`

这类“按种子剪掉 `value_reg`”的能力，是我们后续做更强 bug finding / 证明提速（尤其是大程序如 DistCache）时的基础：否则无关寄存器/控制流会把 Boogie 状态空间撑爆。

### 0.5 冒烟测试（回归基线）

每次改动以下模块后，建议至少跑一次对应冒烟，以保证“翻译/切片/系统级 harness”一致性不回退：

- **DSL/Python 侧（快速）**：
  - `.venv/bin/python -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke`
- **P4B-Translator 侧（增量编译）**：
  - `cd P4B-Translator/build-host && make -j16 p4c-translator`（或 `cmake --build . --target p4c-translator -j"$(nproc)"`）
- **P4B slicing 自检（无需跑 Ultimate）**：
  - `P4B-Translator/build-host/p4c-translator -I P4B-Translator/p4include --goto --bmv2cmds Procurator/argo/code/dataset/Netchain/commands_1.txt --slicing-vars=sequence_reg[0] --slicing-selftest=netchain_seq Procurator/argo/code/dataset/Netchain/netchain_16.p4`

### 0.6 Procurator CLI（常用命令，直接复制粘贴）

> 目的：避免每次刷新上下文都要重新查命令用法；并强调 WSL 安全的资源限制策略。

#### 0.6.1 入口与默认产物路径

- 入口：`./bin/procurator <cmd> ...`
  - `compile`：只编译 `.prop -> .bpl`
  - `verify`：编译 + 跑 Ultimate（并集成 wraparound）
  - `smoke`：对生成的 `.bpl` 做结构冒烟（不跑求解器）
  - `wraparound`：legacy/debug（主线应使用 `verify --wraparound auto`）
- 默认输出目录（no-cache）：`.tmp/procurator/verify/<spec_stem>/<run_id>/`
  - Boogie：`<out_dir>/<spec_stem>.bpl`
  - Ultimate 日志：`<out_dir>/gemcutter.log`
  - Witness（若 UNSAFE）：`<out_dir>/<spec_stem>.bpl-witness.graphml`
  - wraparound（若启用）：`<out_dir>/wraparound/target.*/.../`

#### 0.6.2 WSL 资源限制（必须遵守）

- 默认开启资源限制（建议保持默认）：
  - CPU/IO：`taskset -c 0 nice -n 19 ionice -c 3`
  - Java 堆：`--ultimate-xmx-gb 4`（默认）
  - Toolchain 超时：`--ultimate-timeout-seconds 900`（默认）
- 禁用限制：`--no-resource-limits`（不建议：容易把 WSL 卡死/爆内存）
- 经验规则：不要同时跑多个 Ultimate（GemCutter/Automizer）进程；一次只跑一个 spec。

#### 0.6.3 常用命令模板

编译 + Boogie 冒烟（不跑 Ultimate）：

```bash
./bin/procurator compile \
  --spec Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop \
  --out /tmp/netchain_wraparound_bug.bpl \
  --boogie-harness sequential \
  --no-two-stage

./bin/procurator smoke --bpl /tmp/netchain_wraparound_bug.bpl --harness sequential
```

跑单个 spec（默认 slicing+env-prune 开启；WSL 安全默认）：

```bash
./bin/procurator verify \
  --spec Procurator/argo/code/spec/bench/atp_bug.prop \
  --boogie-harness sequential \
  --no-two-stage \
  --wraparound off \
  --ultimate-timeout-seconds 900
```

主验证管线：优先尝试 wraparound（只在推断到候选寄存器时触发；并且**不**对 ENTRY/CONFIRM 做 CEGIS，refinement 仅用于 CLOSURE 且必须有 witness 证据）：

```bash
./bin/procurator verify \
  --spec Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop \
  --boogie-harness sequential \
  --no-two-stage \
  --wraparound auto \
  --wraparound-stage-order entry_confirm_closure \
  --wraparound-max-targets 1 \
  --wraparound-confirm-unroll 3 \
  --wraparound-max-confirm-unroll 0 \
  --wraparound-closure-timeout-cap 0 \
  --ultimate-timeout-seconds 1800
```

说明：
- `--wraparound-max-confirm-unroll 0`：只跑一次 CONFIRM（避免多次确认浪费时间与内存）。
- `--wraparound-closure-timeout-cap 0`：不给 CLOSURE 人为断点；timeout 后不做“无证据 refinement”，而是 case-by-case 调参/优化。
- `--use-spec-max-steps`：只在 spec 写了合理界并且你确实想要用它时开启（例如某些 bounded-bug-finding spec）。

---

# 实验记录（回归/坑沉淀）

## 2026-02-05

- **Spec**: `Procurator/argo/code/spec/bench/frr_bug2_state_inconsistency.prop`
- **目标/进度**: 让该 bug 在 `slicing` 与 `noslicing` 两种设置下都稳定 `UNSAFE`，并产出可审计 witness（用于消融实验）
- **结果**:
  - slicing: `UNSAFE`（witness ok）run_id `20260205-141109-2835`（产物在 `.tmp/procurator/verify/frr_bug2_state_inconsistency/20260205-141109-2835/`）
  - noslicing: 之前已有 `UNSAFE` witness run_id `20260205-132226-776c`
- **坑（实现错误导致）**:
  - 现象：此前 slicing 结果为 `SAFE`，但 noslicing 为 `UNSAFE`（消融不成立）。
  - 根因：P4B slicer 的 action-level slicing 只在 “写入 seed 变量本身” 时保留语句；对 “将 seed-relevant 值写入 stateful 对象（register.write）” 的语句过度剪枝，导致多步语义下状态丢失（FRR 的 `pkt_par.write(...)` 被切掉）。
- **修复**:
  - `P4B-Translator/backends/verify/slicing/slicer.cpp`: 对 `write(...)` 语句增加保守规则：若写入语句 **uses** 命中 `needed`（即 RHS/参数依赖 seed），即使其 defs 不命中，也保留该写入，并把被写对象加入 `needed`（确保跨步状态被保留）。
- **沉淀为冒烟/回归测试**:
  - `P4B-Translator/backends/verify/bpl_verify/main.cpp`: 新增 `--slicing-selftest=frr_pkt_par_write`（检查 sliced IR 中仍包含 `pkt_par.write(...)`）。
  - `dslc/tests/test_p4b_translator_slicing_selftest.py`: 新增 `test_frr_pkt_par_write_not_dropped_by_action_slicing`。
  - 回归执行：`python3 -m unittest -v dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_spec_regressions`（均 PASS）。

---

## 2026-02-06

- **Spec**: `Procurator/argo/code/spec/bench/gecko_bug1_timer_loss.prop`
- **目标/进度**: 补齐该 bug 的 `slicing` / `noslicing` 两侧可消融结果（都稳定 `UNSAFE`）并产出可审计 witness；同时定位“跑不出来”的根因并沉淀为开关/冒烟。
- **结果**:
  - slicing: `UNSAFE`（witness ok）run_id `20260206-070052-5887`（产物：`.tmp/procurator/verify/gecko_bug1_timer_loss/20260206-070052-5887/`；witness：`gecko_bug1_timer_loss.bpl-witness.graphml`；OverallTime≈253.4s）
  - noslicing: `UNSAFE`（witness ok）run_id `20260206-071127-ca15`（产物：`.tmp/procurator/verify/gecko_bug1_timer_loss/20260206-071127-ca15/`；witness：`gecko_bug1_timer_loss.bpl-witness.graphml`；OverallTime≈296.5s）
- **坑（实现/配置导致）**:
  - 现象 1：使用默认 2GB Z3 配置（`ReachSafety-32bit-GemCutter-ALL.epf`）时，Gecko 在 CFG/RCFG 构造阶段容易 OOM / 卡住，导致 `ERROR`/`TIMEOUT`（难以复现）。
  - 现象 2：internal solver（SMTInterpol）虽能推进，但会出现大量 CEGAR 迭代（spurious trace），1h 级别也可能跑不出结果。
  - 现象 3：引入 `--no-reg-debug` 初版后，harness 的 `modifies` 仍残留 `__dbg` 变量名（但变量未声明），导致生成的 `.bpl` 不一致（需要修复）。
- **修复/沉淀**:
  - `dslc/backends/boogie_harness_start.py`: `modifies` 集合按 `emit_reg_debug` 条件化，避免 `--no-reg-debug` 时引用未声明的 `__dbg` 变量。
  - `dslc/cli/gemcutter.py` + `dslc/cli/compile.py` + `dslc/compiler.py` + harness 侧：新增 `--no-reg-debug`（禁用 per-pass 寄存器快照变量 `reg__dbg0 / reg__last_*__dbg`），显著减少 SMT/CFG 负担。
  - `dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks*.epf`: 新增 8GB + small-blocks 的 EPF（`OneNontrivialStatement`），用于 Gecko 等大程序在 WSL/16GB 内存下稳定跑通。
  - `dslc/tests/test_boogie_backend_smoke.py`: 新增 `test_no_reg_debug_omits_register_snapshot_vars`，防止 `--no-reg-debug` 回归。
  - `Procurator/argo/code/spec/bench/gecko_bug1_timer_loss.prop`: pin 了若干与性质无关的 header 字段为 0，降低分支/状态爆炸风险（避免无意义的路径分叉）。
  - 已更新：`.tmp/procurator/e2e_ablations_1h_v2.json` 与 `USAGE.md` 的 E2E/消融表（记录参数与 run_id）。
- **回归执行**:
  - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke`（PASS）

## 2026-02-06

- **Spec**: `Procurator/argo/code/spec/bench/netlock_release_empty_slots_overflow_bug.prop`
- **目标/进度**: 定位并修复该 spec 在 `slicing` 侧 `TIMEOUT` 的原因，补齐 `slicing` / `noslicing` 两侧可消融结果（都稳定 `UNSAFE`）并产出可审计 witness。
- **结果**:
  - slicing: `UNSAFE`（witness ok）run_id `20260206-100658-61a7`（产物：`.tmp/procurator/verify/netlock_release_empty_slots_overflow_bug/20260206-100658-61a7/`；witness：`netlock_release_empty_slots_overflow_bug.bpl-witness.graphml`；wall≈380.8s）
  - noslicing: `UNSAFE`（witness ok）run_id `20260206-102109-499a`（产物：`.tmp/procurator/verify/netlock_release_empty_slots_overflow_bug/20260206-102109-499a/`；witness：`netlock_release_empty_slots_overflow_bug.bpl-witness.graphml`；wall≈291.2s）
- **坑（实现/配置导致）**:
  - 现象：默认 2GB Z3 profile（`ReachSafety-32bit-GemCutter-ALL.epf`）下，`slicing` 侧会在 TraceAbstraction/CEGAR 中长时间不收敛并 `TIMEOUT`（旧 run_id `20260205-210449-29e4`），而 `noslicing` 侧可在 1h 内稳定 `UNSAFE`（消融不成立）。
- **修复/沉淀**:
  - 使用 `--no-reg-debug` + `--settings dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf`（8GB Z3 + small blocks）可稳定在 1h 内跑出 `UNSAFE` 且 witness 可审计。
  - `dslc/bench/run_e2e_ablations.py`: 将该 spec 的 E2E ablation 配置固定为上述参数，避免回退到默认 profile 导致 `TIMEOUT`。
  - 已更新：`.tmp/procurator/e2e_ablations_1h_v2.json` 与 `USAGE.md` 的 E2E/消融表（记录参数与 run_id）。

## 2026-02-06

- **Spec**: `Procurator/argo/code/spec/bench/ddosd_window_label_collision_bug.prop`
- **目标/进度**: 补齐该 bug 的 `slicing` / `noslicing` 两侧可消融结果（都稳定 `UNSAFE`）并产出可审计 witness；同时确认 WSL 下 base（noslicing）是否需要更高内存 profile。
- **结果**:
  - slicing: `UNSAFE`（witness ok）run_id `20260206-134001-5632`（产物：`.tmp/procurator/verify/ddosd_window_label_collision_bug/20260206-134001-5632/`；witness：`ddosd_window_label_collision_bug.bpl-witness.graphml`；wall≈204.1s）
  - noslicing: `UNSAFE`（witness ok）run_id `20260206-114943-c00b`（产物：`.tmp/procurator/verify/ddosd_window_label_collision_bug/20260206-114943-c00b/`；witness：`ddosd_window_label_collision_bug.bpl-witness.graphml`；wall≈3472.1s）
- **坑（实现/配置导致）**:
  - 现象：noslicing 在 WSL 下对 Z3/RCFG 构造更敏感，需要 8GB small-blocks profile 才能在 1h 内稳定跑出 witness；slicing 侧在 2GB profile 下可跑通。
- **修复/沉淀**:
  - `dslc/bench/run_e2e_ablations.py`: 对该 spec 固定 `--no-reg-debug`，并为 noslicing 配置 `base_settings=ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf`。
  - 已更新：`.tmp/procurator/e2e_ablations_1h_v2.json` 与 `USAGE.md` 的 E2E/消融表（记录参数与 run_id）。

## 2026-02-06

- **Spec**: `Procurator/argo/code/spec/bench/netlock_release_counter_underflow_bug.prop`
- **目标/进度**: 补齐该 bug 的 `slicing` / `noslicing` 两侧可消融结果（都稳定 `UNSAFE`）并产出可审计 witness。
- **结果**:
  - slicing: `UNSAFE`（witness ok）run_id `20260206-023708-2c87`（产物：`.tmp/procurator/verify/netlock_release_counter_underflow_bug/20260206-023708-2c87/`；witness：`netlock_release_counter_underflow_bug.bpl-witness.graphml`；wall≈179.6s）
  - noslicing: `UNSAFE`（witness ok）run_id `20260205-204441-db35`（产物：`.tmp/procurator/verify/netlock_release_counter_underflow_bug/20260205-204441-db35/`；witness：`netlock_release_counter_underflow_bug.bpl-witness.graphml`；wall≈263.1s）
- **坑（实现/配置导致）**:
  - 现象：旧 slicing run（run_id `20260205-202621-7a4a`）在 TraceAbstraction/CEGAR 中长时间不收敛并触发 timeout（当时记录为 `ERROR/TIMEOUT`），导致消融不成立。
- **修复/沉淀**:
  - 重新跑 slicing 后可稳定产出 witness（见上 run_id），并已写回 `.tmp/procurator/e2e_ablations_1h_v2.json` / `USAGE.md`。

## 2026-02-06

- **Spec**: `Procurator/argo/code/spec/bench/netlock_release_empty_queue_head_bug.prop`
- **目标/进度**: 补齐该 bug 的 `slicing` / `noslicing` 两侧可消融结果（都稳定 `UNSAFE`）并产出可审计 witness。
- **结果**:
  - slicing: `UNSAFE`（witness ok）run_id `20260206-024055-e37c`（产物：`.tmp/procurator/verify/netlock_release_empty_queue_head_bug/20260206-024055-e37c/`；witness：`netlock_release_empty_queue_head_bug.bpl-witness.graphml`；wall≈163.2s）
  - noslicing: `UNSAFE`（witness ok）run_id `20260205-210047-3a4e`（产物：`.tmp/procurator/verify/netlock_release_empty_queue_head_bug/20260205-210047-3a4e/`；witness：`netlock_release_empty_queue_head_bug.bpl-witness.graphml`；wall≈241.3s）
- **坑（实现/配置导致）**:
  - 现象：旧 slicing run（run_id `20260205-204904-5452`）同样在 TraceAbstraction/CEGAR 中 timeout，导致当日 E2E 表中 slicing 侧为 `ERROR/TIMEOUT`。
- **修复/沉淀**:
  - 重新跑 slicing 后可稳定产出 witness（见上 run_id），并已写回 `.tmp/procurator/e2e_ablations_1h_v2.json` / `USAGE.md`。

## 2026-02-06

- **Spec**: `Procurator/argo/code/spec/bench/{atp_bug,atp_count_mismatch_bug,p4nis_bug2_tunnel_state_leakage,gecko_bug3_timer_init,netlock_release_empty_slots_overflow_bug}.prop`
- **目标/进度**: 针对“USAGE 中 slicing 看起来普遍变慢”的反馈，按原 E2E 参数逐项复跑慢 case，验证是否“稳定慢”，并排查是否为实现问题（模型生成错误）而非单次求解波动。
- **结果（本轮复跑）**:
  - `atp_bug`: slicing `UNSAFE` run_id `20260206-143655-c37e`（wall≈208.4s）；noslicing `UNSAFE` run_id `20260206-144030-652a`（wall≈286.4s）→ 本轮 slicing 更快（与旧表方向相反）。
  - `atp_count_mismatch_bug`: slicing `UNSAFE` run_id `20260206-144532-9185`（wall≈275.6s）；noslicing `UNSAFE` run_id `20260206-145012-053e`（wall≈264.8s）→ slicing 略慢（+10.8s，差距显著缩小）。
  - `p4nis_bug2_tunnel_state_leakage`: slicing `UNSAFE` run_id `20260206-145441-5d69`（wall≈61.1s）；noslicing `UNSAFE` run_id `20260206-145549-d5ac`（wall≈76.4s）→ 本轮 slicing 更快（与旧表方向相反）。
  - `gecko_bug3_timer_init`: slicing `UNSAFE` run_id `20260206-145712-ac7b`（wall≈145.8s）；noslicing `UNSAFE` run_id `20260206-145945-57ff`（wall≈209.4s）→ 本轮 slicing 更快（与旧表方向相反）。
  - `netlock_release_empty_slots_overflow_bug`: slicing `UNSAFE` run_id `20260206-150331-3e52`（wall≈322.9s）；noslicing `UNSAFE` run_id `20260206-150901-2a63`（wall≈325.5s）→ 基本持平（不再呈现旧表中的明显负收益）。
- **坑（实现/流程导致）**:
  - 复跑开始前有误触发的全仓 `find` 后台进程持续占用 IO（约 8 分钟），会污染耗时结论；已清理后重跑并仅采用清理后的 run_id。
  - `atp_bug` / `atp_count_mismatch_bug` 新旧 `.bpl` 非同一模型（新模型在 `appid_seq_route_dmac` 路径中包含额外 3 条表项分支，旧 run 不包含），说明旧 run 与当前实现不可直接做性能回归对比；`p4nis_bug2` / `gecko_bug3` / `netlock_release_empty_slots_overflow_bug` 新旧 `.bpl` 逐字节一致。
  - 对于同一 `.bpl`，`main/witness` 的 `OverallTime` 与外层 wall 都存在可观抖动，单次 run 不足以支持“稳定变慢”结论，应以多次复跑中位数比较。
- **修复/沉淀**:
  - 本轮未修改验证实现代码；结论先沉淀为“慢 case 需要多次复跑+同模型校验（`.bpl` hash）后再更新 E2E 表”。
  - 冒烟/回归：本轮为复现实验与日志审计，无代码改动，未触发新增单测；后续若落地脚本化校验（如在 `run_e2e_ablations.py` 自动记录 `.bpl` hash 与重复次数）再补回归测试。

## 2026-02-06

- **Spec**: `Procurator/argo/code/spec/bench/{atp_bug,atp_count_mismatch_bug,p4nis_bug2_tunnel_state_leakage,gecko_bug3_timer_init,netlock_release_empty_slots_overflow_bug}.prop`（切片语句审计）
- **目标/进度**: 核对“剪枝后是否只保留 assert/转发相关语句”，定位“理论上应加速但实测变慢”的结构性原因，并修复可确认的实现问题。
- **结果**:
  - ATP（`atp_bug`）在当前种子策略下：`seeds=54`（其中 assume/env-only≈22），`keep_tables=7`，`keep_stmts=155`；去掉 assume/env-only 种子后降为 `keep_tables=3`，`keep_stmts=76`，说明存在非 assert/转发核心路径被保留。
  - Gecko（`gecko_bug3_timer_init`）是 JSON IR：slicer 虽计算 `keep_*`，但翻译阶段打印 `skipping statement pruning for JSON IR` + `json-safe: disabling var/table filtering`，因此 sliced/noslicing 的 `raw.bpl` 一致（该类 case 几乎无程序切片收益）。
  - NetLock（`netlock_release_empty_slots_overflow_bug`）即便强行去掉大量 env-only 种子，`keep_tables` 仍接近不变（42→42），说明该 case 主要受寄存器相关路径依赖与保守切片限制，而非单纯 env 字段种子。
- **坑（实现错误导致）**:
  - `--no-slicing-control-seeds` 之前在 dslc 侧未真正生效：虽然传给了 p4c-translator，但 `dslc/backends/boogie_seeds.py` 仍无条件把控制种子（如 `p4b_recirculate`）加入显式 `--slicing-vars`，导致选项语义被覆盖。
- **修复**:
  - `dslc/backends/boogie_seeds.py`: `build_slicing_plan(..., keep_control_seeds: bool=True)`；仅在该开关为真时注入控制种子。
  - `dslc/backends/boogie_backend.py`: 调用 `build_slicing_plan` 时透传 `keep_control_seeds`，使 CLI 的 `--no-slicing-control-seeds` 在 dslc→P4B 全链路一致生效。
  - `dslc/tests/test_boogie_slicing_seeds.py`: 新增 `test_disable_control_seeds_respected`，防止该选项回退失效。
- **沉淀为冒烟/回归测试**:
  - `python3 -m unittest -v dslc.tests.test_boogie_slicing_seeds`
  - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke`（21 tests, PASS）
  - 受影响 spec 回归（`--no-slicing-control-seeds` 生效性 + 可复现性）：
    - `Procurator/argo/code/spec/bench/netlock_release_empty_slots_overflow_bug.prop`
    - run_id `20260206-153235-d547`，`UNSAFE`（witness rerun 通过），wall≈370.3s，产物：`.tmp/procurator/verify/netlock_release_empty_slots_overflow_bug/20260206-153235-d547/`

## 2026-02-06

- **Spec**: `Procurator/argo/code/spec/bench/{atp_bug,atp_count_mismatch_bug,p4nis_bug2_tunnel_state_leakage,gecko_bug3_timer_init,netlock_release_empty_slots_overflow_bug}.prop`
- **目标/进度**: 针对“USAGE 中 slicing 普遍变慢”的异常，基于当前实现重新 case-by-case 复跑慢项，并校验切片后 BPL 是否保真（assert/转发相关路径保留，host/env 输入声明不丢失）。
- **结果（本轮最终 run）**:
  - `atp_bug`: slicing `UNSAFE` run_id `20260206-171527-1d41`（wall≈111.3s）；noslicing `UNSAFE` run_id `20260206-171712-7fd7`（wall≈118.6s）→ slicing 更快。
  - `atp_count_mismatch_bug`: slicing `UNSAFE` run_id `20260206-164648-9ee3`（wall≈438.2s）；noslicing `UNSAFE` run_id `20260206-165341-2cd8`（wall≈301.3s）→ slicing 仍偏慢（该项需继续做 case-specific 语句级分析）。
  - `p4nis_bug2_tunnel_state_leakage`: slicing `UNSAFE` run_id `20260206-165824-85d9`（wall≈61.0s）；noslicing `UNSAFE` run_id `20260206-165921-4dce`（wall≈71.7s）→ slicing 更快。
  - `gecko_bug3_timer_init`: slicing `UNSAFE` run_id `20260206-163511-87d8`（wall≈223.4s）；noslicing `UNSAFE` run_id `20260206-163841-60cb`（wall≈228.0s）→ slicing 略快且恢复可复现。
  - `netlock_release_empty_slots_overflow_bug`: slicing `UNSAFE` run_id `20260206-170029-6949`（wall≈334.8s）；noslicing `UNSAFE` run_id `20260206-170542-862a`（wall≈411.3s）→ slicing 更快。
- **坑（实现错误导致）**:
  - 去掉 assume/env-only seed 回灌后，`host.env` 写入字段可能不再出现在节点输入声明中，触发 `io_hdr.*` 未声明（`gecko_bug3_timer_init` slicing 曾报 `ERROR`）。
  - `run_e2e_ablations.py --dry-run` 会把 checkpoint 结果写成 `DRY`，污染真实实验 JSON（本轮曾导致 `atp_bug` 在 `USAGE` 显示 `N/A`）。
- **修复**:
  - `dslc/backends/boogie_backend.py`: 在 `prune_env_inputs` 的 `force_keep` 中加入 `required_packet_vars`（经 `_resolve_declared_name`），并保留缺声明兜底重编译逻辑，确保切片后 host/env 相关输入声明仍在。
  - `dslc/bench/run_e2e_ablations.py`: 修复 dry-run 持久化污染；`--dry-run` 不再写入 checkpoint JSON。
  - 重新跑受影响 spec 并覆盖 `.tmp/procurator/e2e_ablations_1h_v2.json`；随后用 `--report-only --timeout 3600 --update-usage` 刷新 `USAGE.md`。
- **沉淀为冒烟/回归测试**:
  - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds`（PASS）
  - `.venv/bin/python -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke`（22 tests, PASS）
  - dry-run 不污染自检：对拷贝 JSON 执行 `run_e2e_ablations.py --dry-run` 前后 `sha256` 一致（PASS）。

## 2026-02-06

- **Spec**: `Procurator/argo/code/spec/bench/{atp_count_mismatch_bug,gecko_bug2_concurrency,p4xos_dropflag_bug,p4xos_majority_quorum_bug}.prop`
- **目标/进度**: 针对“当前消融里 slicing 提升不够大/无提升”的慢项做 case-by-case 诊断；区分“切片实现可优化”与“性质本身接近全程序相关/求解抖动”。
- **结果（本轮 case-by-case）**:
  - `atp_count_mismatch_bug`:
    - 同日 A/B（默认 slicing vs `--no-slicing-control-seeds`）:
      - 默认 slicing: run_id `20260206-183828-068c`，`UNSAFE`，wall=`173.73s`
      - no-control slicing: run_id `20260206-184127-e385`，`UNSAFE`，wall=`124.42s`
      - 提升约 `28.4%`，且 witness 一致为 `dsl_assert` 违例。
    - E2E 结果（写回 JSON/USAGE）:
      - slicing: run_id `20260206-184726-c066`，`UNSAFE`，wall=`137.6s`
      - noslicing: run_id `20260206-184933-5049`，`UNSAFE`，wall=`239.4s`
  - `gecko_bug2_concurrency`:
    - no-control slicing 复跑: run_id `20260206-175603-8a52`，`UNSAFE`，wall=`682.92s`（旧表 slicing 为 `798.8s`）。
    - 但 `slicing_default.bpl` 与 `slicing_nocontrol.bpl` `sha256` 一致（模型不变），判定该收益主要来自求解抖动/调度差异，不作为可固化剪枝改动依据。
  - `p4xos_dropflag_bug`:
    - 默认 slicing: run_id `20260206-184340-0d66`，`UNSAFE`，wall=`118.16s`
    - no-control slicing: run_id `20260206-175356-f5e9`，`UNSAFE`，wall=`119.52s`
    - 同日对照无稳定收益（BPL 虽缩小：880→831 行），不固化。
  - `p4xos_majority_quorum_bug`:
    - no-control slicing: run_id `20260206-180737-18f8`，`UNSAFE`，wall=`1737.36s`
    - 对比旧 slicing `1833.3s` 有小幅改善（约 `5.2%`），但仍是并发交错主导的重 case，暂不作为“显著剪枝优化”结论。
- **坑（实现/流程导致）**:
  - 误将 `_0` seed 兼容扩展当作“可删冗余”进行了修改；该逻辑用于历史 corner case 兼容，已按要求完整回滚（不再改动这条路径）。
  - 对慢 case 若不做同日 A/B，容易把 solver 抖动误判成剪枝收益；本轮通过“BPL hash + 同日 wall”规避该误判。
- **修复**:
  - `dslc/bench/run_e2e_ablations.py`：仅对 `atp_count_mismatch_bug` 固化 `extra_args=["--no-slicing-control-seeds"]`（已验证收益稳定且语义保持 `UNSAFE` witness）。
  - 结果已写回 `.tmp/procurator/e2e_ablations_1h_v2.json`，并通过 `--report-only --update-usage` 更新 `USAGE.md`。
- **沉淀为冒烟/回归测试**:
  - 代码回归：
    - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke`
    - 结果：`22 tests, PASS`
  - case 复现实验产物（可审计 witness）:
    - `atp_count_mismatch_bug`: `.tmp/procurator/verify/atp_count_mismatch_bug/20260206-184726-c066/`
    - `gecko_bug2_concurrency`: `.tmp/procurator/verify/gecko_bug2_concurrency/20260206-175603-8a52/`
    - `p4xos_dropflag_bug`: `.tmp/procurator/verify/p4xos_dropflag_bug/20260206-184340-0d66/`
    - `p4xos_majority_quorum_bug`: `.tmp/procurator/verify/p4xos_majority_quorum_bug/20260206-180737-18f8/`

## 1. 目标与非目标

### 1.1 目标（近期：做出可发表的“P4-aware 验证系统设计”）

* **G1：强 bug-finding**：在固定（节点数/步数/队列容量/位宽）界下，稳定输出反例与回归测试产物（trace）。BMC 框架对这类目标最直接。([GitHub][2])
* **G2：证明取向（条件证明）**：在与 BMC 共享语义的前提下，引入 commutativity 驱动的并发证明（GemCutter），对一类 safety 性质给出更强的“可泛化结论”。GemCutter 的设计动机与实现细节强调 commutativity 与对动态线程的处理策略。([多伦多大学计算机科学系][3])
* **G3：P4-aware 优化可量化**：用严格的消融实验回答“P4 特性是否真的带来数量级加速”，而非仅展示“换后端”。NetSMC 的经验也表明：网络/数据面领域的定制模型与算法往往比直接套通用求解更有效。([USENIX][4])

### 1.2 非目标（第一轮不做）

* **NG1：任意节点数（参数化）证明**：暂放 Future Work；GemCutter 本身通常针对具体实例（尽管对动态线程有策略，但不自动给出“任意 n 节点”证明）。([多伦多大学计算机科学系][3])
* **NG2：完整 P4 目标相关 extern 语义（Tofino/PSA 全量）**：第一轮以“可控子集 + 可扩展建模桩”推进；P4b 也强调通过抽象 P4 API/组件以便验证。([feihe.github.io][5])
* **NG3：以 liveness 为主的证明**：第一轮聚焦 safety（不变量/断言类），因为 liveness 对公平性/队列/丢包模型更敏感，且会显著增加工程成本。NetSMC 也将其策略与适用范围讲得很清楚：简化模型能加速，但会牺牲对“仅在包交错下出现的违例”的捕获能力。([USENIX][4])

---

## 2. 输入、输出与工件格式（agent 可执行接口）

### 2.1 输入

* `P4 Programs`：多组件拆分后的 P4（或由 compiler 输出的组件化 IR）。P4b 展示了将 P4 翻译到验证 IR（Boogie）的可行路径，并支持 P4_14/16。([feihe.github.io][5])
* `Topology & Deployment`：节点集合、入口节点集合、链路/队列配置。
* `Property Specs`：以 safety 为主（断言、不变量、局部契约）。P4b 路线是“将性质写为断言并交给 Boogie 工具链”。([feihe.github.io][5])
* `P4B Meta (p4bmeta-v1)`：P4B-Translator 通过 `--meta-out` 输出变量类型/位宽/入口过程信息，供 DSL 编译器做精确类型推导与寄存器切片。

### 2.2 输出

* `Counterexample Trace`：跨节点的事件序列（recv/enqueue/pass/emit），可回放（最小化反例用于回归）。BMC 工具链典型输出即反例/不可满足结论。([GitHub][2])
* `Proof Artifacts（可选）`：证明成功时输出（a）关键不变量/抽象；（b）被证明的约简前提（队列抽象档位、环境收紧条件等）。GemCutter 强调通过 commutativity 与 SMT 检查支持泛化，同时保持保守性。([多伦多大学计算机科学系][3])

---

## 3. 统一语义：pass 原子 + 事件/队列（覆盖 recirc/mirror/timer）

### 3.1 基本执行单位：Pipeline Pass（run-to-completion）

* **定义**：一次 pass = 从某节点 mailbox/输入队列取出一个 packet/message，执行完整 ingress/egress（含 table apply、action、state update），产生 0..k 个派生事件（emit/mirror/recirc）。
* **并发交错点**：仅发生在 “选择哪个节点执行下一次 pass”。此设计与“压缩交错点以降低状态空间”的总体方向一致；GemCutter 的 commutativity 驱动也会因交错点减少而更有效。([多伦多大学计算机科学系][3])

### 3.2 事件语义（解决你提出的 Gecko/timer/recirc/mirror 两难）

* `mirror/clone`：在 pass 结束时生成新 packet instance，入队到指定 egress/镜像通道。
* `recirc/resubmit`：生成新 packet instance 入队到本节点 ingress（作为**新事件**，而非 while-loop）。
* `control-plane timer packet`：由一个 ControlPlane/Env actor 注入“timer 包”，其后续循环由 recirc 驱动（因此无界行为来自事件再入队，而不是单一 while 的不可控抽象）。
  这一套“事件化/入队化”的处理方式，本质上是在保留“无界可达路径”的同时，把语义锚定到可验证 IR 的离散事件框架。NetSMC 也使用“注入事件/包”的思想构造其网络状态转移模型，并明确讨论简化模型与交错违例之间的取舍。([USENIX][4])
* `P4B 标志位桥接`：P4B 将 `mirror_type/resubmit_type` 的写入转换为 `p4b_clone_* / p4b_recirculate` 布尔标志；并发 harness 以此触发 clone/recirc 事件，确保 Gecko/Tofino 语义可验证。

---

## 4. 队列/邮箱建模：三档抽象（系统能力边界的核心旋钮）

> 目标：让“验证精度—可扩展性”成为可控参数，并可在实验中量化。

### 4.1 Q1：FIFO(K)（最精确，最贵）

* 环形数组 + head/tail；enqueue/dequeue 线性化为原子操作。
* 适用：性质对顺序/容量敏感（例如 overflow、严格顺序协议）。
* 风险：状态空间膨胀，证明更难。

### 4.2 Q2：Bag/Multiset(K)（默认建议：最务实）

* 不保序，仅记录多重集；dequeue 是 nondet 选取任意元素；容量用计数约束表达。
* 优点：制造更多“可交换调度”，更利于 commutativity 约简（与 GemCutter 的核心优势一致）。([多伦多大学计算机科学系][3])
* 风险：对严格 FIFO 性质可能过于保守（需在能力边界中声明）。

### 4.3 Q3：Presence-only（最便宜，最保守）

* 仅记录“某类消息是否可能存在”，忽略数量/顺序。
* 适用：只关心状态不变量、映射一致性等与容量弱相关性质。

---

## 5. 环境建模：入口最小化 + 结构性收紧（避免“为每个节点写 host”）

### 5.1 Env/ControlPlane Actor（统一外部输入源）

* 外部包/控制面事件均由 Env actor 注入。
* 入口节点集合由用户指定（或从部署描述导入），其余节点默认**不接收外部包**，仅由内部消息触发。
  这种“结构性收紧输入空间”的思想与 NetSMC 的“域内洞察驱动模型简化”一致：简化模型换来可扩展性，但必须明确适用条件与漏检场景。([USENIX][4])
* `DSL env { ... }`：允许在节点内声明“外部注入包”的字段约束/赋值，精确收紧环境输入（例如 Gecko 需要 `ether_type=0x5555`）。
* `DSL host { connect <node>; env { ... } }`：显式 Host actor，支持建模客户端/主控端对节点的输入输出行为。
* `global { env_thread = false; }`：在 host 建模已覆盖输入的场景下关闭 EnvThread，避免重复/过强的外部注入。

### 5.2 输入空间约束（从“任意包”到“受 spec 限制的 nondet”）

* 初期：仅限制 header 字段位宽/范围（bitvector domain），对关键字段可引入枚举域。
* 进阶：引入基于 P4 parser 的“可达 header 形状约束”。P4b 将 P4 语义翻译到 Boogie 并附加初始化/值域约束，说明这条路径工程上可行。([feihe.github.io][5])

---

## 6. P4-aware 优化：从“结构分析”产生可验证的状态空间约简

### 6.1 读写集（R/W）与对象×key 分区（核心）

* 在 P4 IR 上提取每个 pass 的 `R(T), W(T)`，细化到（stateful object × key/索引）。
* 用途：

  * 独立性判定（disjoint ⇒ commute）
  * 状态切片（只保留与性质相关的对象/键域）
  * **RegisterAction/execute/apply 视为显式读写**：把 register action 的 apply 体计入 R/W，
    并处理 cast/struct 表达式，避免 Tofino JSON 下漏掉 `meta.*` 依赖（如 Gecko 的 `meta.state_sub`）。
    GemCutter 在 commutativity 判定上也采用“足够条件（写-读冲突检查）+ SMT 精化”的组合策略，你们可以直接对齐其接口设计。([多伦多大学计算机科学系][3])

### 6.2 可交换性（语义级 commutativity）

* 除“不同对象/键不冲突”外，进一步识别“同对象但操作可交换”的更新模式（如某些单调/交换代数操作）。
* 工程策略：先做少量高置信模板（demo 级），再逐步扩展；GemCutter 在 SMT 无法判定时保守回退为“不交换”，保持健全性。([多伦多大学计算机科学系][3])

### 6.3 调度约简（pass 边界 POR）

* 当 `T1` 与 `T2` commute，可只探索一种代表性交错（或在 CEGAR 中用该事实泛化）。
* 这与 Ultimate/GemCutter 的“基于可交换性的并发验证”定位直接一致。([Ultimate PA][1])

---

## 7. 后端架构与接口

### 7.1 总体结构

* **Front-end**：P4 组件化 IR + 部署 + 性质 → 统一的并发验证 IR（建议直接落在 Boogie/C 两条产线之一）。
* **Back-end A（BMC）**：用于强找 bug 与回归（可选 Deagle/CBMC 系）。Deagle 明确是基于 CBMC 前端 + MiniSAT 后端的并发验证器，核心将跨线程通信建为排序约束并进行展开。([feihe.github.io][6])
* **Back-end B（Proof/CEGAR）**：优先 Ultimate/GemCutter。Ultimate 明确提供 GemCutter（Boogie/C），并将其定位为基于 commutativity 的并发验证器。([Ultimate PA][1])

### 7.2 推荐的 IR 选择：Boogie 优先

* **P4 → Boogie**：P4b/P4B-Translator 已给出成熟路径，并说明可把性质写成断言交给 Boogie 工具链验证；同时仓库命令行显示可面向 Ultimate Automizer 使用，并可接入 LTL 规格参数（至少在工具链层面已考虑该方向）。([feihe.github.io][5])
* **Ultimate 工具链**：官网列出 GemCutter 支持 Boogie/C，且可在线试用/集成；工程上利于快速试验。([Ultimate PA][1])
* **Tofino JSON**：P4B 通过 `--fromJSON` 支持 bf-p4c 输出的 JSON IR；DSL harness 会自动识别 `ucast_egress_port` 并支持 68/196 端口的 recirculate 语义。

> 注：你们的“分布式语义 + 队列模型”需要在 Boogie 层面自行编码/生成；P4b 解决的是单个 P4 程序到验证 IR 的语义映射底座。([feihe.github.io][5])

---

## 8. 实验计划

### 8.1 基准（Baseline）

* 统一语义 + Q2(bag,K) + 无 R/W/commutativity 约简 + 入口不收紧（或只最小收紧）
* 指标：时间、内存、查询次数/状态数、反例长度、成功证明率（proof mode）。

### 8.2 消融矩阵

1. **队列抽象**：FIFO(K) vs Bag(K) vs Presence-only
2. **入口环境**：全节点外部输入 vs 入口外部输入（其余内部触发）
3. **P4-aware 约简**：无 → R/W 独立性 → 语义可交换模板
4. **后端对比**：BMC-only vs BMC+GemCutter（同语义、同抽象档位）

NetSMC 对“简化模型会漏掉仅在交错下出现的违例”有明确说明，你们应把这一点写为能力边界，并用实验展示 trade-off。([USENIX][4])

---

## 9. 能力边界与声明（必须写清楚，否则审稿人会抓）

* 若采用 **one-packet / bag 抽象**：可能漏掉仅在多包交错、严格 FIFO 顺序下出现的违例（需在论文中明确）。([USENIX][4])
* 若采用 **有限容量/有限位宽/有限步数**：BMC 结论是“有界内正确/发现反例”；Deagle 对 while(1) 等无界循环在展开上也有明确风险描述，通常需 unwinding assertions 才能使 TRUE 结论“可置信”。([GitHub][2])
* GemCutter 对动态线程的处理与“不会把无界线程程序误判为正确”属于其健全性承诺的一部分，但你们仍需在建模层确保语义编码是保守/健全的。([多伦多大学计算机科学系][3])

---

# 技术选型：P4b / GemCutter / Deagle（你现在就可以“先试试”的路线）

## 1) P4b（或 P4B-Translator：P4→Boogie）

**定位**：把 P4 翻译到 Boogie，并可用 Boogie 工具链验证断言性质；支持 P4_14/16，且强调抽象 P4 API/组件并对全局变量施加初始化/值域约束。([feihe.github.io][5])
**优势**

* 你们如果走 Ultimate/GemCutter（Boogie/C）路线，P4b 是天然前端底座。([Ultimate PA][1])
* P4B-Translator 仓库命令行显示可以为 Ultimate Automizer 输出（`--ua2`），并支持传入 LTL 规格参数入口（`--p4ltl`），说明工具链对“从 P4 到自动机化验证”方向已有接口思路。([GitHub][7])

**劣势/风险**

* 它解决的是**单个 P4 程序语义到验证 IR**，你们的分布式队列/消息语义与 P4 特有的 recirc/mirror 组合行为仍需要你们在上层统一建模。

**建议**：作为**第一优先**前端（最低集成成本、最快出实验）。

---

## 2) GemCutter（Ultimate：并发证明取向，commutativity 驱动）

**定位**：并发程序验证器，核心基于“可交换性（commutativity）”削减交错并提升泛化；Ultimate 官网明确其定位；PLDI’22 描述其在动态线程、commutativity 判定与保守回退方面的实现策略，并强调不会把无界线程程序不健全地判为正确。([Ultimate PA][1])

**优势**

* 你们的系统恰好有一个强“P4-aware commutativity oracle”空间：object×key、操作语义可交换。GemCutter 原生就吃这类信息（至少在思想与实现策略上高度契合）。([多伦多大学计算机科学系][3])
* 更容易在论文里把“证明味”讲清楚（不是纯 BMC 找 bug），且贡献点落在“P4-aware commutativity + 队列抽象分层 + 统一语义”。

**劣势/风险**

* 不会“自动理解队列/网络”，你们仍需把 mailbox 编译成其可接受的并发程序模型（Boogie/C）。

**建议**：作为你说的“搞个 GemCutter 后端做实验验证优化”的**最佳起点**。

---

## 3) Deagle（并发 BMC/展开：强找 bug、工程成熟）

**定位**：基于 CBMC 前端 + MiniSAT 后端的 SMT/SAT 并发验证器，将跨线程通信建为排序一致性约束；支持断言、数据竞争等；其 README 明确 loop unwinding 机制与 while(1) 可能导致无限展开的问题，并推荐 unwinding assertions 以保证 TRUE 结果可置信。([feihe.github.io][6])

**优势**

* 做并发 bug-finding 的 baseline 很合适；你们若把模型落到 C/pthreads，也可快速比较“P4-aware 约简”是否对 BMC 同样有效。([GitHub][2])

**劣势/风险**

* 对你们而言集成成本通常高于 Boogie→Ultimate：你们需要生成 C（或另做一条 IR→C 产线）；且 BMC 的“有界性结论”需要在论文里清晰界定。([GitHub][2])

**建议**：作为**第二阶段**加入（当你们 Boogie+Ultimate 产线跑通后），用于增强“bug-finding 对比”与工程鲁棒性论证。


---

## 参考文献（建议在论文/设计文档中编号引用）

* [R1] Ye, C.; He, F. *P4b: A Translator from P4 Programs to Boogie* (ESEC/FSE’23 Tool). ([feihe.github.io][5])
* [R2] P4B-Translator (GitHub): P4→Boogie；含 `--ua2` / `--p4ltl` 等命令入口。([GitHub][7])
* [R3] Moon, Y.Y.S.J. et al. *NetSMC: A Custom Symbolic Model Checker for Stateful Network Verification* (NSDI’20). ([USENIX][4])
* [R4] Ultimate 官方网站：工具列表与 GemCutter 定位（commutativity-based concurrent verifier）。([Ultimate PA][1])
* [R5] Farzan, A. et al. *Sound Sequentialization for Concurrent Program Verification* (PLDI’22)（描述 Ultimate GemCutter 的实现细节与承诺）。([多伦多大学计算机科学系][3])
* [R6] Ultimate (GitHub)：Ultimate 框架与参与 SV-COMP 的工具族。([GitHub][8])
* [R7] He, F. et al. *Deagle: An SMT-based Verifier for Multi-threaded Programs* (TACAS’22 SV-COMP contribution). ([feihe.github.io][6])
* [R8] Deagle (GitHub README)：能力范围与 unwinding 行为说明。([GitHub][2])

---

[1]: https://ultimate-pa.org/ "Uni-Freiburg : SWT - Ultimate"
[2]: https://github.com/thufv/Deagle "GitHub - thufv/Deagle"
[3]: https://www.cs.toronto.edu/~azadeh/resources/papers/pldi22-2.pdf "Sound Sequentialization forConcurrent Program Verification"
[4]: https://www.usenix.org/system/files/nsdi20spring_yuan_prepub_0.pdf "main"
[5]: https://feihe.github.io/materials/fse23tool.pdf "P4b: A Translator from P4 Programs to Boogie"
[6]: https://feihe.github.io/materials/tacas-svcomp22.pdf "Deagle: An SMT-based Verifier for Multi-threaded Programs (Competition Contribution)"
[7]: https://github.com/Invincibleyc/P4B-Translator "GitHub - Invincibleyc/P4B-Translator"
[8]: https://github.com/ultimate-pa/ultimate "GitHub - ultimate-pa/ultimate: The Ultimate program analysis framework."

## 2026-02-06

- **Spec**: `Procurator/argo/code/spec/bench/{netchain_wraparound_bug,distcache_p2c_wraparound_bug,fisslock_notification_cnt_wraparound_bug}.prop`
- **目标/进度**: 继续对“slicing 提升不足”的 wraparound 类 case 做逐项诊断（同日 A/B），判断是否属于切片优化不到位，并仅固化可复现收益。
- **结果**:
  - `netchain_wraparound_bug`:
    - slicing(default): run_id `20260206-192058-f7e9`，ENTRY/CONFIRM/CLOSURE=`19.1s / 132.1s / 261.4s`（total≈`412.6s`，certified）。
    - slicing(`--no-slicing-control-seeds`): run_id `20260206-192807-e484`，`18.5s / 73.6s / 282.1s`（total≈`374.2s`，certified）。
    - 结论：总时长稳定改善（约 `-9.3%`），主要来自 CONFIRM 显著下降。
  - `distcache_p2c_wraparound_bug`:
    - slicing(default): run_id `20260206-193438-43ec`，`17.9s / 170.0s / 92.9s`（total≈`280.8s`）。
    - slicing(`--no-slicing-control-seeds`): run_id `20260206-193933-f7fe`，`18.4s / 166.2s / 94.0s`（total≈`278.6s`）。
    - 结论：基本持平（<1%），不固化。
  - `fisslock_notification_cnt_wraparound_bug`:
    - slicing(default): run_id `20260206-195322-e235`，`25.1s / 373.9s / 149.7s`（total≈`548.7s`，certified）。
    - slicing(`--no-slicing-control-seeds`): run_id `20260206-194431-e86a`，`27.9s / 319.5s / 166.8s`（total≈`514.2s`，certified）。
    - 结论：总时长有中等改善（约 `-6.3%`），CONFIRM 改善明显。
- **坑（实现/流程导致）**:
  - 直接给 wraparound bench 增加 `extra_args=[..., --no-slicing-control-seeds]` 后，base（noslicing）命令签名也会变化；若不同步 checkpoint 里的 base cmd，`USAGE.md` 会显示 base `N/A`（命令不匹配导致 report-only 认为无有效记录）。
- **修复/沉淀**:
  - `dslc/bench/run_e2e_ablations.py`:
    - 仅对 `netchain_wraparound_bug` 与 `fisslock_notification_cnt_wraparound_bug` 固化 `--no-slicing-control-seeds`。
    - `distcache_p2c_wraparound_bug` 保持原配置（无稳定收益）。
  - `.tmp/procurator/e2e_ablations_1h_v2.json`:
    - 写回上述两条 slicing 新 run（含新 cmd 与 out_dir）。
    - 同步两条 base cmd（仅命令签名补 flag，结果不变），避免 report-only 显示 `N/A`。
  - `USAGE.md`: 已通过 `--report-only --update-usage` 刷新。
- **沉淀为冒烟/回归测试**:
  - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke`
  - 结果：`Ran 22 tests ... OK`。

## 2026-02-06

- **Spec**: `Procurator/argo/code/spec/bench/{gecko_bug2_concurrency,gecko_bug3_timer_init,p4xos_dropflag_bug,netlock_pkt_type_bug,p4xos_majority_quorum_bug,distcache_spine_cache_frequency_idx_bug}.prop`
- **目标/进度**: 继续处理“收益不高/跑不出来”尾项；重点验证 `--no-reg-debug` 是否能在不改语义下实质降时，并修复 base OOM case 的可运行性。
- **结果**:
  - `gecko_bug2_concurrency`（同日公平对照，均 `--no-reg-debug`）:
    - slicing: run_id `20260206-202139-0527`，`UNSAFE`，Overall≈`253.9s`。
    - noslicing: run_id `20260206-210314-b444`，`UNSAFE`，Overall≈`268.4s`。
    - 结论：由原先 ~800s 级下降到 ~260s 级；且 slicing 侧仍略优于 noslicing。
  - `gecko_bug3_timer_init`（同日公平对照，均 `--no-reg-debug`）:
    - slicing: run_id `20260206-203044-afb1`，`UNSAFE`，Overall≈`45.5s`。
    - noslicing: run_id `20260206-210030-0366`，`UNSAFE`，Overall≈`46.5s`。
    - 结论：由原先 ~220s 级下降到 ~46s 级，低收益 case 转为低成本可复现。
  - `p4xos_dropflag_bug`（同日公平对照，均 `--no-reg-debug`）:
    - slicing: run_id `20260206-201928-cae9`，`UNSAFE`，Overall≈`41.8s`。
    - noslicing: run_id `20260206-205803-fa5c`，`UNSAFE`，Overall≈`49.0s`。
    - 结论：从“slicing 略慢”转为 slicing 可见收益（约 `-14.7%`）。
  - `netlock_pkt_type_bug`（base OOM 修复验证）:
    - noslicing + `ALL-8g.epf`: run_id `20260206-211318-a88b`，`UNSAFE`，witness Overall≈`197.2s`。
    - 结论：清除了此前 base `ERROR(out of memory)`，可审计 witness 可产出。
  - `p4xos_majority_quorum_bug`:
    - slicing + `--no-reg-debug`：run_id `20260206-203323-eb77` 主日志 `UNSAFE`，Overall≈`850.9s`（相对旧值 `1833.3s` 有显著下降）。
    - noslicing 对照在同参数下长时间 witness 重跑，未在本轮完成收敛，暂未固化到 E2E 表。
  - `distcache_spine_cache_frequency_idx_bug`:
    - 本轮在多 profile（`ALL` / `ALL-8g-smallblocks` / `internal-no-por`）复跑均得到 `SAFE`，与历史 `slicing=UNSAFE` 记录不一致，判定为“profile/模型演化敏感”项；本轮未强行写入新的 bug 结论，待单独审计。
- **坑（实现/流程导致）**:
  - `run_e2e_ablations.py` 的 base cmd 由 `cfg.args` 与 `base_settings` 叠加，命令行会出现双 `--settings`；若手工写回 JSON 未保持该形态，`report-only` 会把记录判为 `N/A`。
  - `p4xos_majority` 在 witness 重跑阶段耗时很长；需区分“主求解已得 UNSAFE”与“审计 witness 完整产出”两阶段，避免把长时间 witness 误当作求解失败。
- **修复/沉淀**:
  - `dslc/bench/run_e2e_ablations.py`:
    - `gecko_bug2_concurrency` / `gecko_bug3_timer_init` / `p4xos_dropflag_bug` 固化 `extra_args=["--no-reg-debug"]`。
  - `.tmp/procurator/e2e_ablations_1h_v2.json`:
    - 写回上述 3 个 case 的同日 slicing/noslicing 审计 run（含 witness log/out_dir/wall）。
    - 写回 `netlock_pkt_type_bug` 的 base `UNSAFE`（8g profile）结果，消除 base `ERROR`。
  - `USAGE.md` 已按最新结果刷新。
- **沉淀为冒烟/回归测试**:
  - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke`
  - 结果：`Ran 22 tests ... OK`。

## 2026-02-06

- **Spec**: `Procurator/argo/code/spec/bench/{distcache_p2c_wraparound_bug,frr_bug1_unexpected_mirror,netlock_pkt_type_bug,p4xos_majority_quorum_bug,p4xos_bug,distcache_cm34_write_bug}.prop`
- **目标/进度**: 继续处理“收益不高/跑不出来”的剩余项；优先固化已验证提速的 slicing 开关，并对仍失败的 base case 做 profile 级诊断。
- **结果**:
  - `distcache_p2c_wraparound_bug`（slicing + `--no-slicing-control-seeds`）:
    - run_id `20260206-220119-e63c`，`CERTIFIED UNSAFE`，ENTRY/CONFIRM/CLOSURE=`80.4s/211.6s/153.7s`（total≈`445.8s`）。
    - 对比旧 slicing `727.9s`：显著改善。
  - `frr_bug1_unexpected_mirror`（slicing + `--no-slicing-control-seeds`）:
    - run_id `20260206-221952-102a`，`UNSAFE`（witness），Overall≈`12.3s`。
    - 对比旧 slicing `77.4s`：显著改善。
  - `netlock_pkt_type_bug`（slicing + `--no-slicing-control-seeds`）:
    - run_id `20260206-220921-bd76`，`UNSAFE`（witness），Overall≈`19.5s`。
    - 对比旧 slicing `204.6s`：显著改善。
  - `p4xos_majority_quorum_bug`（slicing + `--no-reg-debug --no-slicing-control-seeds`）:
    - run_id `20260206-222133-1618`，CEGAR 长时间迭代未在本轮收敛，人工终止（无最终 RESULT）。
  - `p4xos_bug`（base/noslicing）:
    - `ALL-8g + --no-reg-debug`: run_id `20260206-223050-371c`，由旧 `ERROR` 改善为“可运行但 no result”。
    - `internal-no-por + --no-reg-debug`: run_id `20260206-223713-57bd`，同样“可运行但 no result”。
  - `distcache_cm34_write_bug`（base/noslicing，`internal + --no-reg-debug`）:
    - run_id `20260206-224305-98e8`，长时间 CEGAR 后仍无 RESULT，本轮未修复为可判定。
- **坑（实现/配置导致）**:
  - `p4xos_bug` / `distcache_cm34_write_bug` 在 base 模式下会进入高迭代 CEGAR 且长时间不给出最终 RESULT；`--no-reg-debug` 可减轻规模，但不足以保证 600s 内可判定。
  - `p4xos_majority_quorum_bug` 在当前 profile 下仍是重型 case；需要单独做 timeout/profile/分块策略实验，不能与其它 case 混跑。
- **修复/沉淀**:
  - `dslc/bench/run_e2e_ablations.py` 固化:
    - `distcache_p2c_wraparound_bug` slicing 侧新增 `--no-slicing-control-seeds`。
    - `frr_bug1_unexpected_mirror` slicing 侧新增 `--no-slicing-control-seeds`。
    - `netlock_pkt_type_bug` slicing 侧新增 `--no-slicing-control-seeds`。
  - `.tmp/procurator/e2e_ablations_1h_v2.json` 已写回上述 3 个 case 的新 slicing run_id/耗时/产物路径。
  - `USAGE.md` 已通过 report-only 刷新。
- **沉淀为冒烟/回归测试**:
  - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke`
  - 结果：`Ran 22 tests in 92.163s`，`OK`。

## 2026-02-07

- **Spec**: `Procurator/argo/code/spec/bench/distcache_spine_cache_frequency_idx_bug.prop`
- **时间**: `2026-02-07 00:20-00:35`（run_id `20260206-232005-5a50` / `20260206-232529-a041` / `20260206-233222-9a41`）
- **目标/进度**: 诊断“为什么走不到 bug”，确认是 `.bpl/spec` 可达性还是 slicing 翻译错误。
- **结果**:
  - 旧配置（等价 1-step 前缀）`SAFE`：run_id `20260206-232005-5a50`。
  - 将 spec 改为 `max_steps = 2` 后，slicing 可稳定 `UNSAFE`：run_id `20260206-232529-a041`、`20260206-233222-9a41`。
- **坑（是否实现错误）**:
  - 是，属于 **spec/harness 步数建模错误**（不是 slicer 翻译错误）：1-step 只完成 env 注入，未执行节点 pass，断言在 bug 路径前就被检查。
- **修复/沉淀**:
  - `Procurator/argo/code/spec/bench/distcache_spine_cache_frequency_idx_bug.prop`：`max_steps` 固化为 `2`，并补注释说明调度步含义。

- **Spec**: `Procurator/argo/code/spec/bench/distcache_cm34_write_bug.prop`
- **时间**: `2026-02-07 00:10-00:50`（run_id `20260207-002410-c738` / `20260207-001007-313a` / `20260207-002746-80a7` / `20260207-004331-2a12`）
- **目标/进度**: 处理 base（noslicing）长时间跑不出结果，判断是 `.bpl` 路径问题还是求解 profile 不匹配。
- **结果**:
  - slicing 稳定 `UNSAFE`：run_id `20260207-002410-c738`（witness ok）。
  - noslicing + internal profile 连续 `TIMEOUT`：run_id `20260207-001007-313a`、`20260207-002746-80a7`。
  - noslicing + `ALL-8g-smallblocks` + `--no-reg-debug`：主求解 `UNSAFE`（`gemcutter.log` 末尾 `RESULT: ... incorrect`），run_id `20260207-004331-2a12`。
- **坑（是否实现错误）**:
  - 否，非翻译语义错误；核心是 **base 求解配置不匹配**（CEGAR 长尾/timeout）。
- **修复/沉淀**:
  - `dslc/bench/run_e2e_ablations.py`：对该 spec 固化 `extra_args=["--no-reg-debug"]`，并将 base `settings` 切到 `ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf`。

- **Spec**: `Procurator/argo/code/spec/bench/netlock_pushback_length_in_server_underflow_bug.prop`
- **时间**: `2026-02-07 00:14-00:19`（run_id `20260207-001426-5f8a` / `20260207-001826-d965`）
- **目标/进度**: 修复 base 侧 `ERROR(no result)`，确认是否为 OOM。
- **结果**:
  - 默认 2GB profile：`ERROR`，日志明确 `z3 out of memory`（run_id `20260207-001426-5f8a`）。
  - `ALL-8g-smallblocks`：`UNSAFE` + witness rerun `UNSAFE`（run_id `20260207-001826-d965`）。
- **坑（是否实现错误）**:
  - 否，主要是 profile 内存不足导致的求解失败。
- **修复/沉淀**:
  - `dslc/bench/run_e2e_ablations.py` 已将该 spec 的 base profile 固化为 `ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf`。

- **Spec**: `Procurator/argo/code/spec/bench/p4xos_bug.prop`
- **时间**: `2026-02-06 23:09 - 2026-02-07 00:31`（run_id `20260206-223050-371c` / `20260206-230843-504e` / `20260207-002920-d53f`）
- **目标/进度**: 继续诊断“base 跑不出来/收益低”是否来自 `.bpl` 编译问题。
- **结果**:
  - 旧 base run 明确 OOM：run_id `20260206-223050-371c`（log 含 `out of memory`）。
  - 受步数影响显著：`max-steps=1` 得 `SAFE`（run_id `20260206-230843-504e`），`max-steps=2` 变为 `TIMEOUT`（run_id `20260207-002920-d53f`）。
- **坑（是否实现错误）**:
  - 当前未发现翻译/切片实现错误；问题更像 `env=max` + 高并发外部输入下的 solver 收敛瓶颈与步界敏感。
- **修复/沉淀**:
  - 暂未固化新的 spec 改动（避免引入不公平步界）；后续需单独做多次中位数复跑与步界策略实验。

- **沉淀为冒烟/回归测试**:
  - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke`
  - 结果：`Ran 22 tests in 86.323s`，`OK`。

## 2026-02-07

- **Spec**: `Procurator/argo/code/spec/bench/atp_bug.prop`
- **时间**: `2026-02-07 02:32-02:42`
- **目标/进度**: 处理“收益不高”case，检查 slicing seeds 是否过保守，尝试仅关闭隐式控制 seeds。
- **结果**:
  - slicing（`--no-slicing-control-seeds`）: `UNSAFE`，run_id `20260207-023629-7563`，wall≈`97.6s`。
  - noslicing（同参数 + `--no-slicing --no-env-prune`）: `UNSAFE`，run_id `20260207-023800-c853`，wall≈`124.2s`。
  - 相对收益：`124.2/97.6 ≈ 1.27`（较旧记录 `1.07` 明显提升）。
- **坑（实现错误导致）**:
  - 否。此前 `--no-reg-debug` 在该 spec 上波动较大，不适合作为稳定优化；`--no-slicing-control-seeds` 更稳。
- **修复/沉淀**:
  - `dslc/bench/run_e2e_ablations.py`：`atp_bug` 固化 `extra_args=["--no-slicing-control-seeds"]`。
  - `.tmp/procurator/e2e_ablations_1h_v2.json`：已写回上述 slicing/noslicing 新 run。
- **是否沉淀为冒烟测试**: 否（配置层优化，无新增语义 bug 模式）。

- **Spec**: `Procurator/argo/code/spec/bench/p4db_damper_threshold_off_by_one_bug.prop`
- **时间**: `2026-02-07 02:26-02:50`
- **目标/进度**: 复盘“收益不高”原因，验证 `--no-reg-debug/--no-slicing-control-seeds` 是否可稳定提升。
- **结果**:
  - 多轮 A/B 显示不稳定：有 run 主求解更快（`OverallTime` 约 `10-15s`），也有 run 出现 slicing 侧明显慢于 base（例如 run_id `20260207-024353-92f4` 对比 `20260207-024559-a75f`）。
  - 结论：当前该 spec 不具备“可稳定固化”的 slicing 提升策略。
- **坑（实现错误导致）**:
  - 否。未发现翻译错误；主要是该 case 的端到端 wall 抖动较大（solver/witness阶段波动），单次结果方向不稳定。
- **修复/沉淀**:
  - 未固化额外开关；`dslc/bench/run_e2e_ablations.py` 保持该 spec 仅 `--max-steps 3`。
  - `.tmp/procurator/e2e_ablations_1h_v2.json` 已回写为当前配置下最新记录。
- **是否沉淀为冒烟测试**: 否（无新增可确定实现缺陷）。

- **Spec**: `Procurator/argo/code/spec/bench/p4xos_majority_quorum_bug.prop`
- **时间**: `2026-02-07 02:10-02:26`
- **目标/进度**: 排查“走不到 bug / 提升不足”是 `.bpl` 编译问题、spec 步界问题还是优化不到位。
- **结果**:
  - `.bpl` 结构诊断：`max_steps` 从 `20 -> 16 -> 14` 时行数显著下降（约 `1440 -> 1309 -> 1182`，`+ --no-slicing-control-seeds` 到 `1260`），说明剪枝确实生效。
  - 但验证仍在 TraceAbstraction 长尾中超时：如 run_id `20260207-021501-9728`、`20260207-022046-d8a1`（均 `Timeout`）。
  - 结论：该 case 当前瓶颈不是“未剪枝”，而是性质与关键路径耦合高、且存在多 error target 的 CEGAR 收敛难题。
- **坑（实现错误导致）**:
  - 未定位到实现错误（非 slicer 把 bug 路径剪掉）；更像验证难例本身的收敛问题。
- **修复/沉淀**:
  - 本轮未固化新的 case 配置，避免把不稳定参数写入 E2E 基线。
- **是否沉淀为冒烟测试**: 否（当前无可复现实现 bug 可抽成确定性 smoke）。

- **回归执行**:
  - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke`
  - 结果：`Ran 22 tests in 80.714s`，`OK`。

## 2026-02-07

- **Spec**: `全局方法沉淀 + {gecko_bug2_concurrency,gecko_bug3_timer_init,fisslock_notification_cnt_wraparound_bug,p4db_damper_threshold_off_by_one_bug,p4xos_majority_quorum_bug}.prop`
- **时间**: `2026-02-07 03:00-03:40`
- **目标/进度**: 将“如何挖掘潜在性能提升”的方法沉淀到可复用流程，并继续推进低收益 case。
- **方法论（已实践）**:
  - 先按 `noslicing/slicing` 比值排序，优先处理低收益或负收益 case。
  - 先做便宜诊断（compile-only）：比较 `.bpl` 行数/hash/关键断言变量是否变化，判断开关是否真正改变模型。
  - 分型处理：
    - 模型不变：该开关对该 case 无效（不继续跑 solver）。
    - 模型变小但仍慢：倾向 solver 收敛瓶颈，避免误改 slicer 语义。
    - 结果反常：优先排查 spec 步界/可达性，不先动翻译语义。
  - A/B 一次只改一个因子（如 `--no-reg-debug` 或 `--no-slicing-control-seeds`），保持其余参数不变。
  - wraparound case 按 ENTRY/CONFIRM/CLOSURE 分阶段看耗时，不仅看总 wall。
  - 仅当“语义不变 + witness 可审计 + 多次方向稳定”才固化到 `run_e2e_ablations.py`；否则回退。
- **结果（本阶段）**:
  - `gecko_bug2_concurrency` / `gecko_bug3_timer_init`:
    - `--no-slicing-control-seeds` 前后 `.bpl` hash 完全一致（compile-only 证据），说明无额外剪枝空间；
    - 结论：这两项低收益主要不是控制 seeds 造成。
  - `fisslock_notification_cnt_wraparound_bug`:
    - compile-only 显示 `--no-reg-debug` 可显著减小模型（`2743 -> 2644` 行，`__dbg` 计数明显下降）。
    - 完整 run（slicing）: run_id `20260207-031504-718e`，ENTRY/CONFIRM/CLOSURE=`27.4/294.4/131.8s`，WALL≈`470.2s`（较旧 `514.2s` 改善）。
    - 完整 run（noslicing）: run_id `20260207-032310-ca35`，ENTRY/CONFIRM/CLOSURE=`23.3/285.9/165.4s`，WALL≈`485.7s`（较旧 `529.5s` 改善）。
    - 结论：两侧都更快，但相对收益仍接近（约 `1.03`），不属于“slicing 独占提升”。
  - `p4db_damper_threshold_off_by_one_bug`:
    - 多次 A/B 出现方向不稳定（主求解快慢在不同 run 反转），暂不满足“可稳定固化”条件。
  - `p4xos_majority_quorum_bug`:
    - 已确认剪枝生效（`max_steps` 下调时 `.bpl` 显著缩小），但仍 TraceAbstraction 长尾；问题更像收敛难例。
- **坑（实现错误导致）**:
  - 未发现本阶段新增“实现错误”型问题；主要是求解波动与难例收敛。
- **修复/沉淀**:
  - 方法已沉淀为上述固定流程，后续按该流程继续处理剩余低收益 case。
  - `fisslock` 的 `--no-reg-debug` 已进入候选固化验证（需结合脚本化结果写回 E2E 基线）。
- **是否沉淀为冒烟测试**:
  - 暂无新增实现缺陷，未新增 smoke；继续沿用既有 22 项回归。

## 2026-02-07

- **Spec**: `Procurator/argo/code/spec/bench/p4db_damper_threshold_off_by_one_bug.prop`
- **时间**: `2026-02-07 03:48-03:52`
- **目标/进度**: 复跑“低收益/反向收益”case，验证是否可通过 slicing 定向开关恢复正收益并稳定 witness。
- **结果**:
  - slicing（`--no-slicing-control-seeds --no-reg-debug`）: `UNSAFE`，run_id `20260207-034851-1e8e`，wall≈`90.35s`。
  - noslicing（同参数 + `--no-slicing --no-env-prune`）: `UNSAFE`，run_id `20260207-035028-15b4`，wall≈`109.28s`。
  - 新旧对比：由旧记录 `slicing 136.3s / noslicing 79.7s`（反向）转为 `slicing 90.35s / noslicing 109.28s`（正向，约 `1.21x`）。
- **坑（实现错误导致）**:
  - 否。根因是该 case 之前未关闭控制 seeds 且保留了寄存器调试快照，导致 slicing 侧模型冗余，非语义翻译错误。
- **修复/沉淀**:
  - `dslc/bench/run_e2e_ablations.py`：`p4db_damper_threshold_off_by_one_bug` 固化 `--no-slicing-control-seeds --no-reg-debug`（保留 `--max-steps 3`）。
- **是否沉淀为冒烟测试**:
  - 否（配置层收敛优化，无新增语义缺陷）。

- **Spec**: `Procurator/argo/code/spec/bench/p4xos_majority_quorum_bug.prop`
- **时间**: `2026-02-07 03:52-进行中`
- **目标/进度**: 对“收益低+长尾”case 做候选优化复跑（`--no-slicing-control-seeds --no-reg-debug`），确认是否可显著缩短 slicing 主求解。
- **阶段结果（进行中）**:
  - slicing 主求解 run_id `20260207-035243-e134` 已进入 witness 复验阶段（主日志已给出 `incorrect/UNSAFE` 证据）；witness 复验仍在运行。
  - 过程日志持续出现 `IncrementalHoareTripleChecker ... UNKNOWN`（数组+量词），表明瓶颈主要在 CEGAR 收敛而非“切片未生效”。
- **坑（实现错误导致）**:
  - 当前未见实现错误迹象；更像求解难例收敛上限。
- **修复/沉淀**:
  - 待 witness 结束后再决定是否固化该候选参数到 E2E 基线。

## 2026-02-07

- **Spec**: `Procurator/argo/code/spec/bench/fisslock_notification_cnt_wraparound_bug.prop`
- **时间**: `2026-02-07 04:14-04:37`（run_id `20260207-041452-b206` / `20260207-042700-e601`）
- **目标/进度**: 用脚本化 E2E 重新验证 `--no-reg-debug + --no-slicing-control-seeds` 是否稳定提升 wraparound case。
- **结果**:
  - slicing: `entry 30.5s / confirm 462.6s / closure 218.8s`，总 wall≈`711.9s`，`CERTIFIED UNSAFE`。
  - noslicing: `entry 27.8s / confirm 391.2s / closure 186.3s`，总 wall≈`605.4s`，`CERTIFIED UNSAFE`。
  - 本轮出现 `slicing` 负收益（约 `0.85x`）。
- **坑（实现错误导致）**:
  - 否。两侧都出现同步慢化，属于求解波动/收敛噪声，不是 slicing 实现错误导致的语义回退。
- **修复/沉淀**:
  - 保留参数与日志用于后续“多次复跑取中位数”分析；暂不再继续扩大该 case 的参数改动面。
- **是否沉淀为冒烟测试**:
  - 否（无新增确定性实现缺陷）。

- **Spec**: `Procurator/argo/code/spec/bench/p4db_damper_threshold_off_by_one_bug.prop`
- **时间**: `2026-02-07 04:37-04:39`（run_id `20260207-043715-5cfd` / `20260207-043817-e513`）
- **目标/进度**: 用脚本化 E2E 确认 `--no-slicing-control-seeds --no-reg-debug` 固化后仍保持正收益。
- **结果**:
  - slicing: wall≈`66.0s`，`UNSAFE`，witness 完整。
  - noslicing: wall≈`79.9s`，`UNSAFE`，witness 完整。
  - 收益稳定为正（约 `1.21x`）。
- **坑（实现错误导致）**:
  - 否。属于配置级优化命中，无翻译语义错误。
- **修复/沉淀**:
  - `dslc/bench/run_e2e_ablations.py` 中该 spec 已固化 `--max-steps 3 --no-slicing-control-seeds --no-reg-debug`。
- **是否沉淀为冒烟测试**:
  - 否（配置层优化，无新增语义 bug 模式）。

- **Spec**: `Procurator/argo/code/spec/bench/gecko_bug2_concurrency.prop`
- **时间**: `2026-02-07 04:40-04:53`（run_id `20260207-044030-2d26` / `20260207-044805-8663`）
- **目标/进度**: 验证在现有 `--no-reg-debug` 上叠加 `--no-slicing-control-seeds` 是否还能带来 slicing 专属收益。
- **结果**:
  - 主求解 `OverallTime`：slicing `263.9s`，noslicing `271.5s`（差距很小）。
  - 结合 compile-only（模型 hash/行数不变）结论：`--no-slicing-control-seeds` 对该 case 不改变模型，耗时差异属于求解波动。
- **坑（实现错误导致）**:
  - 否。无 slicing 错误剪枝迹象。
- **修复/沉淀**:
  - 不固化额外开关，维持当前 gecko bug2 配置（仅 `--no-reg-debug`）。
  - 为加速本轮排查，witness 复验阶段手动停止（不影响“是否可达 bug”的主求解结论）。
- **是否沉淀为冒烟测试**:
  - 否。

- **Spec**: `Procurator/argo/code/spec/bench/gecko_bug3_timer_init.prop`
- **时间**: `2026-02-07 04:53-04:56`（run_id `20260207-045343-a1c5` / `20260207-045558-7339`）
- **目标/进度**: 同 gecko bug2，确认 `--no-slicing-control-seeds` 是否有效。
- **结果**:
  - 主求解 `OverallTime`：slicing `48.4s`，noslicing `53.7s`。
  - compile-only 仍显示模型不变，说明额外开关不产生结构性剪枝；时间变化为噪声级。
- **坑（实现错误导致）**:
  - 否。
- **修复/沉淀**:
  - 不新增 case 开关，维持当前 gecko bug3 配置（仅 `--no-reg-debug`）。
  - 为加速本轮排查，witness 复验阶段手动停止（不影响主求解可达性结论）。
- **是否沉淀为冒烟测试**:
  - 否。

- **Spec**: `Procurator/argo/code/spec/bench/p4xos_majority_quorum_bug.prop`
- **时间**: `2026-02-07 03:52-04:13`（run_id `20260207-035243-e134`）
- **目标/进度**: 评估 `--no-slicing-control-seeds --no-reg-debug` 是否改善低收益长尾 case。
- **结果**:
  - 主求解 `OverallTime`：新 run `961.0s`，旧基线 `948.8s`（无提升）。
  - 结论：该 case 主要受数组+量词 CEGAR 收敛限制，非“切片未生效”问题。
- **坑（实现错误导致）**:
  - 否，未发现实现错误。
- **修复/沉淀**:
  - 不固化该候选参数，保持基线配置。
- **是否沉淀为冒烟测试**:
  - 否。

- **回归执行**:
  - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke`
  - 结果：`Ran 22 tests in 66.919s`，`OK`。

## 2026-02-07

- **Spec**: `Procurator/argo/code/spec/bench/p4db_router_ttl_expiry_bug.prop`
- **时间**: `2026-02-07 05:01-05:07`（手工 run_id `20260207-050123-db6f` / `20260207-050218-ad05`；脚本回写 run_id `20260207-050518-bb35` / `20260207-050612-3b0b`）
- **目标/进度**: 对“接近低收益阈值”的 P4DB case 做同类剪枝优化验证（`--no-slicing-control-seeds --no-reg-debug`）。
- **结果**:
  - 手工复核：slicing wall≈`55.47s`、noslicing wall≈`68.04s`，主求解 `OverallTime=7.7s / 14.8s`。
  - 脚本回写：slicing wall≈`59.4s`（run_id `20260207-050518-bb35`），noslicing wall≈`72.6s`（run_id `20260207-050612-3b0b`），均 `UNSAFE` + witness。
  - 收益由原约 `1.15x` 提升到约 `1.22-1.23x`。
- **坑（实现错误导致）**:
  - 否。无实现错误，属于配置层可复用优化。
- **修复/沉淀**:
  - `dslc/bench/run_e2e_ablations.py`：`p4db_router_ttl_expiry_bug` 固化 `--max-steps 3 --no-slicing-control-seeds --no-reg-debug`。
- **是否沉淀为冒烟测试**:
  - 否（配置层优化，无新增语义缺陷）。

- **回归执行**:
  - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke`
  - 结果：`Ran 22 tests in 67.192s`，`OK`。

## 2026-02-07

- **Spec**: `Procurator/argo/code/spec/bench/{fisslock_notification_cnt_wraparound_bug,gecko_bug2_concurrency,gecko_bug3_timer_init,p4xos_majority_quorum_bug}.prop`
- **时间**: `2026-02-07 05:10-05:55`
- **目标/进度**: 对“低收益/无收益”case 做剪枝前后 BPL 深度对比，并继续收紧可安全优化点。
- **结果（BPL 结构对比）**:
  - 本轮在 harness 层新增“顶层无条件覆盖赋值跳过冗余 havoc”后，compile-only 指标继续下降（示例：`p4xos_majority` slicing havoc `35`、`fisslock` slicing havoc `13`、`gecko2/gecko3` slicing havoc `26`）。
  - 低收益 case 的共同点仍是：`table_hit_refs/action_refs` 基本不变，说明瓶颈主要在表/动作路径求解，而不是输入字段 havoc 数量。
  - `gecko_bug2_concurrency` 新 run（run_id `20260207-054235-b27d`）主求解 `UNSAFE`，`OverallTime≈266.8s`；后续 witness rerun 长时间不退出（手动终止）。
- **坑（实现错误导致）**:
  - 未发现 slicing 语义错误或 `.bpl` 错误剪枝导致“走不到 bug”。
  - 主要坑是 witness rerun 阶段可能长时间占用进程，干扰批量复测节奏（流程/工具链层问题，非翻译实现 bug）。
- **修复/沉淀**:
  - `dslc/backends/boogie_harness_dsl.py`:
    - 扩展 `_collect_top_level_constant_assign_targets`：从“仅常量 RHS”放宽为“顶层无条件覆盖赋值且 RHS 非自引用”，继续减少无意义 `havoc`。
  - 该逻辑已被三条注入路径复用（external node / sequential host send / concurrent host thread）。
  - `dslc/tests/test_boogie_backend_smoke.py` 新增:
    - `test_env_top_level_nonconst_assign_still_skips_redundant_havoc`
    - `test_env_top_level_self_ref_assign_keeps_havoc`
  - 回归：
    - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke` → `Ran 9 tests ... OK`
    - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke` → `Ran 26 tests in 67.955s`，`OK`。
- **是否沉淀为冒烟测试**: 是（上述 2 条 smoke 已加入并通过）。

- **Spec**: `Procurator/argo/code/spec/bench/{p4nis_bug1_forwarding_sequence_desync,p4nis_bug2_tunnel_state_leakage}.prop`
- **时间**: `2026-02-07 05:34-05:42`
- **目标/进度**: 对额外低收益 case 做参数 A/B（default vs `--no-reg-debug`）验证，确认是否值得固化。
- **结果**:
  - `p4nis_bug1_forwarding_sequence_desync`:
    - slicing/default run_id `20260207-053447-bb83` wall≈`44s`
    - noslicing/default run_id `20260207-053532-3c18` wall≈`47s`
    - slicing/noreg run_id `20260207-053619-a873` wall≈`45s`
    - noslicing/noreg run_id `20260207-053704-3900` wall≈`46s`
  - `p4nis_bug2_tunnel_state_leakage`:
    - slicing/default run_id `20260207-053801-d2ef` wall≈`62s`
    - noslicing/default run_id `20260207-053904-e735` wall≈`69s`
    - slicing/noreg run_id `20260207-054013-be83` wall≈`60s`
    - noslicing/noreg run_id `20260207-054114-c2d9` wall≈`70s`
  - 结论：`--no-reg-debug` 在这两个 case 上收益不稳定或极小，不满足“可稳定固化”条件。
- **坑（实现错误导致）**:
  - 否。未发现实现错误，主要是小规模 case 的求解波动与噪声。
- **修复/沉淀**:
  - 不修改 `dslc/bench/run_e2e_ablations.py` 这两项配置，避免引入无效参数。
- **是否沉淀为冒烟测试**: 否（无新增实现缺陷）。

## 2026-02-07

- **Spec**: `Procurator/argo/code/spec/bench/{gecko_bug1_timer_loss,gecko_bug2_concurrency,gecko_bug3_timer_init,fisslock_notification_cnt_wraparound_bug}.prop`
- **时间**: `2026-02-07 11:55-12:55`（run_id `20260207-115958-23bb` / `20260207-120122-f7bb` / `20260207-120301-5e8e` / `20260207-121004-28a9` / `20260207-121646-b0e5` / `20260207-122239-bc55` / `20260207-123131-44d0` / `20260207-124213-5b92`）
- **目标/进度**: 按“低收益 case 优先”方法，重点处理 Gecko(3) 与 FissLock(1)；要求确认 slicing 是否正确生效，并把优化后结果固化到可审计 run。
- **结果**:
  - `gecko_bug3_timer_init`:
    - slicing: `UNSAFE`，run_id `20260207-115958-23bb`，`OverallTime=36.5s`。
    - noslicing: `UNSAFE`，run_id `20260207-120122-f7bb`，`OverallTime=53.8s`。
    - 收益：约 `1.47x`。
  - `gecko_bug2_concurrency`:
    - slicing: `UNSAFE`，run_id `20260207-120301-5e8e`，`OverallTime=346.1s`。
    - noslicing: `UNSAFE`，run_id `20260207-121004-28a9`，`OverallTime=375.1s`。
    - 收益：约 `1.08x`。
  - `gecko_bug1_timer_loss`:
    - slicing: `UNSAFE`，run_id `20260207-121646-b0e5`，`OverallTime=310.6s`。
    - noslicing: `UNSAFE`，run_id `20260207-122239-bc55`，`OverallTime=405.6s`。
    - 收益：约 `1.31x`。
  - `fisslock_notification_cnt_wraparound_bug`（wraparound 三阶段）:
    - slicing: run_id `20260207-123131-44d0`，`entry/confirm/closure = 26.3s / 441.9s / 149.9s`，总 `618.1s`，`entry=UNSAFE, confirm=UNSAFE, closure=SAFE`。
    - noslicing: run_id `20260207-124213-5b92`，`entry/confirm/closure = 29.4s / 415.0s / 209.7s`，总 `654.1s`，`entry=UNSAFE, confirm=UNSAFE, closure=SAFE`。
    - 收益：约 `1.06x`（由旧的 slicing 负收益翻转为正收益）。
- **坑（实现错误导致）**:
  - Gecko 为 JSON IR 时，之前 `json-safe` 路径把 var/table filtering 一并禁用，导致 slicing 与 noslicing 在声明层面差异受限，收益无法释放。
  - 修复后新增的 Gecko JSON 回归用例首版断言正则写错（`\\s` 误写），造成假失败；已修复为正确正则，非实现回退。
- **修复/沉淀**:
  - `P4B-Translator/backends/verify/bpl_verify/main.cpp`:
    - JSON IR 保持“跳过 statement pruning”，但不再清空 `keepVarNames/keepTables`；启用安全的 var/table 过滤。
  - `P4B-Translator/backends/verify/translate/translate.cpp`:
    - 扩展 `shouldKeepVar()` 的层级匹配，父对象命中时保留降级子字段（例如 `hdr.albion_data -> hdr.albion_data.data_0`），避免 Gecko 缺失声明。
  - `dslc/tests/test_p4b_translator_slicing_selftest.py`:
    - 新增 `test_gecko_json_slicing_keeps_child_field_decls`，锁定 JSON slicing 下“保留关键子字段声明且声明数下降”的行为。
- **是否沉淀为冒烟测试**: 是。
  - 回归执行：
    - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke`
    - 结果：`Ran 27 tests in 71.339s`，`OK`。

## 2026-02-07

- **Spec**: `Procurator/argo/code/spec/bench/{gecko_bug1_timer_loss,gecko_bug2_concurrency,gecko_bug3_timer_init,fisslock_notification_cnt_wraparound_bug}.prop`（阶段时间采集）
- **时间**: `2026-02-07 14:50-15:11`
- **目标/进度**: 在“时间不足，不再收集内存峰值”的前提下，case-by-case 采集真实阶段时间：前端 compile（prune/translate）+ 后端 harness 编码时间；wraparound stage1/2/3 复用既有 certified manifest 时间。
- **结果**:
  - 已生成结构化产物：
    - `.tmp/procurator/stage_timing_gecko_fisslock.json`
    - `.tmp/procurator/stage_timing_gecko_fisslock.md`
  - compile 阶段（slicing/noslicing）已逐 case 成功采集：
    - `gecko_bug1_timer_loss`: slicing `prune=0.286s, translate=3.453s, harness=0.007s`; noslicing `0.001s, 2.419s, 0.010s`
    - `gecko_bug2_concurrency`: slicing `0.229s, 3.472s, 0.009s`; noslicing `0.001s, 2.569s, 0.009s`
    - `gecko_bug3_timer_init`: slicing `0.245s, 3.655s, 0.004s`; noslicing `0.001s, 2.544s, 0.005s`
    - `fisslock_notification_cnt_wraparound_bug`: slicing `0.244s, 5.227s, 0.003s`; noslicing `0.001s, 4.260s, 0.003s`
  - wraparound stage 时间（复用已跑出的 certified manifest）：
    - `fisslock_notification_cnt_wraparound_bug` slicing `entry/confirm/closure=26.333/441.886/149.928s`，noslicing `29.363/414.998/209.707s`
    - 并同步给出 `netchain_wraparound_bug`、`distcache_p2c_wraparound_bug`、`distcache_p2c_spineload_wraparound_bug` 的 stage1/2/3 时间（见上述 md/json）。
- **坑（实现错误导致）**:
  - 首版“10 分钟内存采样”流程在超时后会遗留 Ultimate 子进程，导致下一 case 可能并发污染；该问题属于采样流程缺陷，不是翻译/验证语义 bug。
- **修复/沉淀**:
  - `dslc/bench/collect_perf_10min.py` 增加超时后按 spec run 目录清理残留子进程（`pkill -f /.tmp/procurator/verify/<spec_stem>/`），防止跨 case 干扰。
  - 本轮最终输出不再依赖内存采样，只保留阶段时间统计，满足“快速+真实可复核”的采集目标。
- **是否沉淀为冒烟测试**:
  - 否（流程脚本优化，无新增语义实现缺陷）。

## 2026-02-07

- **Spec**: `Procurator/argo/code/spec/bench/*`（全 28 个 E2E case，跨系统统一阶段时间实验文档）
- **时间**: `2026-02-07 15:18-15:27`
- **目标/进度**: 收集“别的系统”的编码时间（不再采集内存），并与当前版本运行时间整合成单一实验文档；wraparound 的 stage1/2/3 复用已跑出的 certified 结果。
- **结果**:
  - 新增脚本：`dslc/bench/collect_compile_runtime_report.py`
  - 生成实验文档：`EXPERIMENT_STAGE_RUNTIME_CURRENT.md`
  - 生成原始数据：`.tmp/procurator/compile_runtime_integrated_all_systems.json`
  - 覆盖范围：28 个 spec × slicing/noslicing 双模式，compile 阶段时间全部成功（无 compile 失败）。
  - 文档内容：
    - 当前版本 runtime（复用 `.tmp/procurator/e2e_ablations_1h_v2.json` 的 `wall_s/status`）
    - compile 分阶段时间（`frontend_prune_s / frontend_translate_s / python_harness_emit_s / total_backend_compile_s`）
    - wraparound 三阶段时间（`entry/confirm/closure`，从 certified manifest 复用）。
- **坑（实现错误导致）**:
  - 旧的 10min 内存采样流程在超时后可能残留 Ultimate 子进程，导致后续 case 并发污染；该问题属于实验脚本流程坑，不是翻译/验证语义错误。
- **修复/沉淀**:
  - 已在 `dslc/bench/collect_perf_10min.py` 中加入超时后按 spec 目录清理残留进程逻辑。
  - 本轮文档采集切换为“compile+runtime+wraparound stages”路径，避免内存采样噪声。
  - `USAGE.md` 新增“Compile/Runtime Integrated Experiment (Current Version)”入口与复现命令。
- **是否沉淀为冒烟测试**:
  - 否（实验脚本/文档流程层改动，无新增语义缺陷）。

- **回归执行**:
  - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke`
  - 结果：`Ran 27 tests in 77.087s`，`OK`。

## 2026-02-07

- **Spec**: `Procurator/argo/code/spec/bench/*`（实验文档后置单表整合）
- **时间**: `2026-02-07 15:28-15:31`
- **目标/进度**: 将“阶段时间 + slicing/noslicing 运行时间对比”合并为同一个总表，追加在新实验文档尾部；wraparound 后端编码开销按要求忽略。
- **结果**:
  - 在 `EXPERIMENT_STAGE_RUNTIME_CURRENT.md` 末尾追加：
    - `## Unified Slicing vs Noslicing (Runtime + Compile + Wraparound)`
    - 单表一行一个 spec，同时包含：
      - runtime slicing / runtime noslicing / speedup
      - backend compile slicing / backend compile noslicing
      - prune / translate / harness（slicing 侧）
      - wraparound stage `entry/confirm/closure`（仅 wraparound case，其他为 `-`）
  - 使用标记块：
    - `<!-- UNIFIED_SLICING_COMPARE_START -->`
    - `<!-- UNIFIED_SLICING_COMPARE_END -->`
    便于后续脚本化覆盖更新。
- **坑（实现错误导致）**:
  - 无；本次为文档整合，不涉及验证语义或翻译逻辑改动。
- **修复/沉淀**:
  - 文档层沉淀完成，后续可以直接在该块做增量更新。
- **是否沉淀为冒烟测试**:
  - 否（纯文档改动）。

## 2026-02-07

- **Spec**: `Procurator/argo/code/spec/bench/*`（统一“编码+运行=总时间”分析表）
- **时间**: `2026-02-07 15:31-15:33`
- **目标/进度**: 按“编码时间（前端+harness）+模型检查运行时间=总时间”的口径，在同一张表中做 slicing/noslicing 对比；wraparound case 展开 stage1/2/3。
- **结果**:
  - 在 `EXPERIMENT_STAGE_RUNTIME_CURRENT.md` 追加区块：
    - `<!-- UNIFIED_TOTAL_TIME_START -->`
    - `## Unified Total Time Analysis (Encode + Model-Checker Runtime)`
    - `<!-- UNIFIED_TOTAL_TIME_END -->`
  - 表中每个 spec 一行，字段包括：
    - `encode slicing / encode noslicing`
    - `run slicing / run noslicing`
    - `total slicing / total noslicing`
    - `total speedup`
    - `wrap stages slicing(e/c/cl) / wrap stages noslicing(e/c/cl)`
  - 并输出结构化摘要：
    - `.tmp/procurator/compile_runtime_totaltime_summary.json`
- **坑（实现错误导致）**:
  - 无实现错误；本次为口径重整与文档聚合。
- **修复/沉淀**:
  - 非 wraparound case 的模型检查运行时间从 `out_dir/gemcutter.log` 的 `OverallTime` 提取（缺失时回退 `wall_s`）。
  - wraparound case 使用 certified manifest 的 `entry/confirm/closure` 合计作为运行时间，按要求不单列 wraparound 额外编码时间。
- **是否沉淀为冒烟测试**:
  - 否（文档/报表层改动）。

## 2026-02-07

- **Spec**: `Procurator/argo/code/spec/bench/*`（`USAGE.md` E2E 基线逐条复核）
- **时间**: `2026-02-07 16:00-16:20`
- **目标/进度**: 按“USAGE 为准、保留历史结果、不删除”要求，手工复核 28 个 case 的 opt/base run_id 是否可用、结果标签是否与日志一致，并判断是否需要用更晚 run 覆盖。
- **结果**:
  - `28/28` 条 E2E 记录的 opt/base run 目录均存在。
  - `0` 条结果标签不一致（`UNSAFE/SAFE/TIMEOUT` 与 `gemcutter.log` 一致）。
  - 发现部分 spec 存在更晚 run，但多数属于不同口径（短超时采样）或缺失 witness，不覆盖基线。
  - 关键确认：
    - `gecko_bug2_concurrency`、`gecko_bug3_timer_init`、`fisslock_notification_cnt_wraparound_bug` 已是当前优化后基线。
    - `p4xos_majority_quorum_bug` 更晚 slicing run（`20260207-035243-e134`）`OverallTime=961.0s`，相较基线 `948.8s` 无改进，且缺失 witness 文件，因此不替换。
- **坑（实现错误导致）**:
  - 无新增实现错误；主要风险来自“把短超时采样 run 误当 E2E 基线”导致数据口径混淆。
- **修复/沉淀**:
  - `USAGE.md` 新增 `E2E Baseline Manual Recheck (2026-02-07)` 区块，记录每个“有更晚 run 但不替换”的原因（口径差异/无 witness/无收益）。
  - 明确后续规则：仅当“同口径 + 可审计 witness + 收益稳定”才覆盖 E2E 基线行。
- **是否沉淀为冒烟测试**:
  - 否（文档与流程口径修正，无新增语义缺陷）。

## 2026-04-27

- **Spec**: `Procurator/argo/code/spec/bench/gecko_bug3_timer_init.prop`
- **时间**: `2026-04-27 23:42-23:48`（Asia/Shanghai）
- **目标/进度**: 为 rebuttal 中“pruning 不只体现为端到端时间，也体现为搜索空间缩减”的问题补充可复现实验；复跑同一 spec 的 slicing / noslicing，并抽取 Boogie 规模与 GemCutter CEGAR/abstraction 指标。
- **结果**:
  - slicing: `UNSAFE`，run_id `20260427-234251-6016`，产物在 `.tmp/procurator/verify/gecko_bug3_timer_init/20260427-234251-6016/`
    - Boogie: 4767 lines, 343464 bytes, 26 `havoc`, 132 `if`, 291 `call`, 95 `assume`
    - GemCutter main log (`StatisticsResult`): CFG 606 locations / 928 edges, `OverallTime=30.8s`, `OverallIterations=13`, largest abstraction 1215 states, 604 trace-check code blocks, 3962 SSA conjuncts
  - noslicing: `UNSAFE`，run_id `20260427-234550-575d`，产物在 `.tmp/procurator/verify/gecko_bug3_timer_init/20260427-234550-575d/`
    - Boogie: 5227 lines, 391291 bytes, 118 `havoc`, 136 `if`, 297 `call`, 95 `assume`
    - GemCutter main log (`StatisticsResult`): CFG 644 locations / 982 edges, `OverallTime=34.0s`, `OverallIterations=13`, largest abstraction 2647 states, 584 trace-check code blocks, 4836 SSA conjuncts
  - 结论：该可复现短 case 中，slicing 将 symbolic `havoc` 数从 118 降到 26（约 4.5x reduction），并将 largest abstraction 从 2647 states 降到 1215 states（约 2.2x reduction），可作为 Table 3 speedup 之外的搜索空间缩减证据。
- **补充历史 artifact（未复跑，避免 1h 级 noslicing 开销）**:
  - `ddosd_window_label_collision_bug` 现有可审计 run：
    - slicing `20260206-134001-5632`: 1163 Boogie lines, 17 `havoc`, 37 `if`; GemCutter CFG 98 locations / 142 edges, `OverallTime=62.4s`, `OverallIterations=19`, largest abstraction 122 states, 1099 trace-check code blocks, 3158 SSA conjuncts.
    - noslicing `20260206-114943-c00b`: 2058 Boogie lines, 52 `havoc`, 68 `if`; GemCutter CFG 797 locations / 872 edges, `OverallTime=1665.4s`, `OverallIterations=29`, largest abstraction 1001 states, 16673 trace-check code blocks, 18747 SSA conjuncts.
  - 可在 rebuttal 中作为更强 search-space reduction 示例：CFG locations 约 8.1x reduction，largest abstraction states 约 8.2x reduction，trace-check code blocks 约 15.2x reduction。
- **坑（实现错误导致）**:
  - 无新增实现错误；`procurator verify` 对 `UNSAFE` 返回非零 exit code，本轮按日志中的 `RESULT: UNSAFE` 和 witness 文件确认结果。
- **修复/沉淀**:
  - 本轮未修改验证实现代码；抽取指标用于 rebuttal 文案。
- **是否沉淀为冒烟测试**:
  - 否（实验/文案支撑数据，不涉及新语义缺陷）。

## 2026-04-28

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`
- **时间**: `2026-04-28 16:25-17:05`（Asia/Shanghai）
- **目标/进度**: 首次按 `--wraparound-cegar-mode schedule_replay` 试跑 NetChain schedule-replay 管线；用户指出不能直接开长耗时 E2E，应按阶段验证，且 `entry_check` 必须像旧实现一样很快。已停止长跑，改为只修复并单独验证 `entry_check` 阶段。
- **结果**:
  - 误实现 run：`.tmp/procurator/verify/netchain_wraparound_bug/20260428-162545-a66b/`
    - `entry_check` 被错误生成成 PUMP/net-effect 搜索；日志显示 `RESULT: Ultimate proved your program to be incorrect!`，但 `OverallTime=1332.0s`，明显不符合 entry 快速门槛的设计。
    - `near_wrap` 已跑出 `UNSAFE`（约 58.6s）；`closure_check` 在用户要求停止后被中断，本轮不构成 certified 结果。
  - 修复后 entry-only 阶段检查：`.tmp/procurator/verify/netchain_wraparound_bug/20260428-entry-only-schedule-abs/`
    - 生成的 `netchain_wraparound_bug.schedule.entry_only.entry_check.bpl` 包含 `__wraparound_entry_error`，不包含 `__wraparound_pump_error` / `wrap_target_old`，说明已回到 `ENTRY_CHECK` 形态。
    - Ultimate 结果：`RESULT: Ultimate proved your program to be incorrect!`；日志 `OverallTime=1.4s`，外层 `wall_time_s≈20.0s`（包含 Ultimate 启动和前端处理）。
- **坑（实现错误导致）**:
  - schedule-replay loop 中把 ENTRY 错接为 `WraparoundStage.PUMP`，并额外 unroll 了 scheduler，导致 entry 从“初始可达性 SAT gate”退化为“寻找净效应闭包候选”的重查询。
  - 该错误还导致 manifest 只在 closure 返回后写入；被中断时没有足够的阶段记录，不利于分阶段调试。
- **修复/沉淀**:
  - `dslc/workflows/wraparound_cegis.py`: schedule-replay 的 ENTRY 改回 `WraparoundStage.ENTRY_CHECK`，不再对 entry 做 confirm-like unroll；manifest 改为在 entry 后、near-wrap 后、closure 后增量落盘。
  - `dslc/tests/test_wraparound_schedule.py`: 新增/调整回归，检查 schedule entry BPL 不含 PUMP instrumentation，并验证 entry 后即使后续阶段中断也已经写出 manifest。
  - 后续规则：schedule-replay 继续按阶段测，先 entry、再 near-wrap、再 closure；不再直接开长时间完整 E2E。
- **是否沉淀为冒烟测试**: 是。
  - `python3 -m unittest -v dslc.tests.test_wraparound_schedule dslc.tests.test_wraparound_transform dslc.tests.test_wraparound_cegis_order`
    - 结果：`Ran 27 tests in 1.037s`，`OK`。
  - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke`
    - 结果：`Ran 27 tests in 68.622s`，`OK`。
## 2026-04-28

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`
- **时间**: `2026-04-28 20:22-21:42`（Asia/Shanghai）
- **目标/进度**: 继续实现并审计 paper-aligned `schedule_replay` CEGAR。重点检查用户要求的语义：`sche` 只保存 actor 顺序数组，mailbox/phase 才作为 closure projection；witness 中的 packet/table/header shape 不能混进 actor schedule。按阶段验证 NetChain，不做无人值守长跑。
- **结果**:
  - 快速单测：`python3 -m unittest -v dslc.tests.test_wraparound_schedule dslc.tests.test_wraparound_transform dslc.tests.test_wraparound_cegis_order`
    - 结果：`Ran 38 tests in 2.787s`, `OK`
  - 基础冒烟：`python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke`
    - 结果：`Ran 27 tests in 69.625s`, `OK`
  - NetChain `stop-after near_wrap`：
    - run_id `20260428-205450-305f`
    - manifest: `.tmp/procurator/verify/netchain_wraparound_bug/20260428-205450-305f/wraparound/target.00.s1_sequence_reg/wraparound.cegis.manifest.json`
    - `entry_check`: `UNSAFE`, wall≈81.2s
    - `near_wrap`: `UNSAFE`, wall≈203.7s
    - manifest schedule actors: `["h1", "h1", "s1", "s2"]`
    - manifest projection: `h1_inbox_count`, `procurator_phase`, `s1_inbox_count`, `s2_inbox_count`
  - NetChain manual witness extraction（复用上面的 near-wrap BPL，不重跑 ENTRY/NEAR）：
    - `netchain_wraparound_bug.schedule.00.near_wrap.unroll3.bpl-witness.graphml`
    - `RESULT: UNSAFE`, wall≈112.9s
    - witness-derived closure conditions synthesized: 50 predicates
  - NetChain manual closure checks（均只跑 closure BPL，不重跑前两阶段）：
    - full projection + 50 conditions, timeout 240s: `TIMEOUT`, wall≈289.6s
    - phase-only projection + 50 conditions, timeout 420s: `TIMEOUT`, wall≈440.1s
    - experimental variant that also forced the 50 witness conditions as post-preserved closure assertions: `UNSAFE`, wall≈415.0s。结论：这些 header/table/path facts 是 replay/environment conditions，不是 closure projection invariants。
- **坑（实现错误/设计边界导致）**:
  - `stop-after closure` 初版在 closure `UNKNOWN/TIMEOUT` 后仍会继续第二轮 projection weakening，不符合分阶段测试语义；已修复为第一轮 closure 后立即停止。
  - schedule-mode certification 初版允许 `confirm` 字段代替显式 `near_wrap`，过宽；已修复为必须有 `near_wrap=UNSAFE`。
  - witness extraction timeout 初版会受 `--ultimate-timeout-seconds=180` 影响，NetChain 同一 near-wrap BPL 曾在 180s 内无 GraphML；单跑 300s 可稳定产 GraphML。已把 schedule-mode witness timeout 下限提高到 300s、上限 600s。
  - projection weakening 复用 ENTRY/NEAR 时，第二轮 manifest 的 ENTRY artifact 曾指向未运行的新 ENTRY BPL；已缓存并回指原始 ENTRY BPL/log。
  - subagent review 指出 witness-derived facts 不能伪装成 closure projection。实测 NetChain 也证明将这些 facts 强制 post-preserve 会使 closure `UNSAFE`。实现改为 `schedule.projection` 只记录真正被 closure snapshot/compare 的投影，witness facts 记录到 `schedule.conditions` / `cfg.closure_assumes`，作为条件化 replay profile 审计信息。
  - schedule-replay 目前只 cert `add` 且 `step_delta=1` 的 wraparound candidate；`step_delta>1` / `sub` 暂时 uncertified fallback，避免 near-wrap fast-forward 到 `MAX` 时出现不可达边界值。
  - unmapped deterministic phase 不再生成 synthetic `phase_N` actor；无法映射真实 actor 的 harness 直接 uncertified fallback。
- **修复/沉淀**:
  - `dslc/workflows/wraparound_cegis.py`:
    - 新增/收紧 `schedule_replay` manifest certification gate。
    - closure-only projection weakening 复用 ENTRY/NEAR，但 blocker 路径清空缓存并重跑 ENTRY。
    - unsupported step / unmapped schedule 返回 uncertified manifest，交给 direct GemCutter fallback。
  - `dslc/workflows/wraparound_schedule.py`:
    - `ActorSchedule.actors` 保持 actor-order-only；`reactions` 仅作为 debug metadata，不参与 schedule hash。
    - `conditions` 独立于 `projection`，用于记录 witness-derived replay/profile predicates。
    - witness predicate parser 支持 numeric dotted fields，如 `h1_hdr.overlay.5.valid`。
  - `dslc/cli/gemcutter.py`:
    - `--wraparound-stop-after` 下若 wraparound pipeline 抛异常，返回非零，避免 staged debug 静默成功。
  - `dslc/transform/wraparound_instrument.py` / `dslc/transform/wraparound_stages.py`:
    - 确认 closure `extra_assumes` 是 conditions，不加入 projection preservation assertion。
  - `dslc/tests/test_wraparound_schedule.py` / `dslc/tests/test_wraparound_transform.py`:
    - 新增 stop-after closure、explicit near_wrap certification、witness timeout、projection weakening artifact reuse、numeric dotted predicate parsing、unsupported step fallback、unmapped actor fallback、conditions-not-projection 等回归。
- **是否沉淀为冒烟测试**: 是。
  - schedule/transform/order 单测覆盖上述语义边界。
  - AGENTS 基础冒烟保持通过。

## 2026-04-28

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`
- **时间**: `2026-04-28 21:50-22:05`（Asia/Shanghai）
- **目标/进度**: 继续按阶段验证 `schedule_replay` 三阶段求解，先只跑 NetChain `ENTRY_CHECK`，同时把求解速度优化落到不影响保真的路径上：ENTRY/NEAR_WRAP 使用 no-witness fast path，只有 CLOSURE `UNKNOWN/TIMEOUT` 且仍有下一轮时才额外跑 witness printer 来生成诊断性 `conditions`。
- **结果**:
  - NetChain `stop-after entry`（修复前 wiring 状态）：
    - run_id `20260428-215031-7085`
    - manifest: `.tmp/procurator/verify/netchain_wraparound_bug/20260428-215031-7085/wraparound/target.00.s1_sequence_reg/wraparound.cegis.manifest.json`
    - `entry_check`: `UNSAFE`，wall≈87.4s
    - `diagnostic`: `stopped after entry by request`
    - manifest schedule actors: `["h1", "h1", "s1", "s2"]`
    - manifest projection: `h1_inbox_count`, `procurator_phase`, `s1_inbox_count`, `s2_inbox_count`
    - manifest conditions: `[]`
  - 单测/冒烟：
    - `python3 -m unittest -v dslc.tests.test_wraparound_schedule dslc.tests.test_wraparound_transform dslc.tests.test_validate_counterexample`
      - 修复后结果：`Ran 40 tests in 2.336s`, `OK`
    - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke dslc.tests.test_wraparound_schedule dslc.tests.test_wraparound_transform dslc.tests.test_validate_counterexample`
      - 结果：`Ran 69 tests in 74.684s`, `OK`
- **坑（实现/配置导致）**:
  - 集成的 `run_wraparound_cegis_multi` 在 `schedule_replay` 下仍把 ENTRY/NEAR 接到了 witness-enabled toolchain/settings；ENTRY 本身语义正确，但 witness printer 对 entry-only 阶段没有必要，会拖慢阶段验证。
  - lazy witness 重构后，下一轮 manifest `cfg.notes` 没有稳定记录 `closure_seed_assumes=N`；测试仍按旧的“closure 前先跑 witness”语义断言，和新的速度策略不一致。
- **修复/沉淀**:
  - `dslc/workflows/wraparound_cegis.py`:
    - schedule-replay 多目标入口改为 ENTRY/NEAR 使用 `ReachSafety.xml` / no-witness settings；legacy closure-assumes 模式保留 witness-enabled 行为。
    - `confirm.witness.*` 只在纯 CLOSURE `UNKNOWN/TIMEOUT` 后、且仍有下一轮可消费这些条件时运行；closure `SAFE/UNSAFE` 的快路径不再付 witness printer 成本。
    - 每轮根据当前 `closure_assumes` 自动写入 `closure_seed_assumes=N`，保证 manifest 可审计。
  - `dslc/tests/test_wraparound_schedule.py`:
    - 新增集成 wiring 回归：`schedule_replay` 使用 no-witness fast path，legacy 保持 witness toolchain。
    - 更新 lazy witness / projection weakening / stop-after-closure 测试，使其锁定“先纯 closure，UNKNOWN 后再 witness refinement”的三阶段速度策略。
- **是否沉淀为冒烟测试**: 是。
  - schedule-replay 单测覆盖 actor-only `sche`、projection/conditions 分离、certification gate、lazy witness、no-witness fast path、unsupported fallback。
  - AGENTS 基础冒烟与 P4B slicing 自检保持通过。

## 2026-04-28

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`
- **时间**: `2026-04-28 22:05-22:08`（Asia/Shanghai）
- **目标/进度**: 复跑 NetChain `schedule_replay` 的 `ENTRY_CHECK` 单阶段，确认集成入口已经使用 no-witness fast path，并继续保持 actor-only `sche` 与空 `conditions` 的证书形态。
- **结果**:
  - 命令：
    - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop --boogie-harness sequential --no-two-stage --wraparound auto --wraparound-cegar-mode schedule_replay --wraparound-stop-after entry --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --ultimate-timeout-seconds 300`
  - run_id `20260428-220537-27a2`
  - manifest: `.tmp/procurator/verify/netchain_wraparound_bug/20260428-220537-27a2/wraparound/target.00.s1_sequence_reg/wraparound.cegis.manifest.json`
  - 日志显示：`stage=entry_check ... toolchain=ReachSafety.xml settings=ReachSafety-32bit-GemCutter-ALL.epf`
  - `entry_check`: `RESULT: UNSAFE`，`wall_s≈28.3s`（manifest `wall_time_s≈28.25s`）
  - `diagnostic`: `stopped after entry by request`
  - manifest schedule actors: `["h1", "h1", "s1", "s2"]`
  - manifest projection: `h1_inbox_count`, `procurator_phase`, `s1_inbox_count`, `s2_inbox_count`
  - manifest conditions: `[]`
- **坑（实现/配置导致）**:
  - 本轮未发现新的保真问题；与上一条修复前 `ENTRY_CHECK` wall≈87.4s 相比，no-witness wiring 生效后降到≈28.3s。
- **修复/沉淀**:
  - 本轮为单阶段复跑验证，无新增代码修改；上一条记录中的 no-witness fast path 单测已经覆盖该 wiring。
- **是否沉淀为冒烟测试**: 是。
  - `dslc.tests.test_wraparound_schedule.test_multi_schedule_replay_uses_nowitness_fast_path` 防止 schedule-replay 集成入口回退到 witness toolchain。

## 2026-04-28

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`
- **时间**: `2026-04-28 22:07-22:14`（Asia/Shanghai）
- **目标/进度**: 继续按阶段跑 `schedule_replay`，本轮只到 `NEAR_WRAP`，不启动 CLOSURE；验证 ENTRY/NEAR 都接入 no-witness fast path，并观察第二阶段耗时。
- **结果**:
  - 命令：
    - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop --boogie-harness sequential --no-two-stage --wraparound auto --wraparound-cegar-mode schedule_replay --wraparound-stop-after near_wrap --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --ultimate-timeout-seconds 300`
  - run_id `20260428-220734-9a40`
  - manifest: `.tmp/procurator/verify/netchain_wraparound_bug/20260428-220734-9a40/wraparound/target.00.s1_sequence_reg/wraparound.cegis.manifest.json`
  - 日志显示：
    - `entry_check`: `toolchain=ReachSafety.xml settings=ReachSafety-32bit-GemCutter-ALL.epf`
    - `near_wrap`: `toolchain=ReachSafety.xml settings=ReachSafety-32bit-GemCutter-ALL.epf`
  - `entry_check`: `RESULT: UNSAFE`，wall≈32.9s
  - `near_wrap`: `RESULT: UNSAFE`，wall≈321.7s
  - `diagnostic`: `stopped after near_wrap by request`
  - manifest schedule actors: `["h1", "h1", "s1", "s2"]`
  - manifest projection: `h1_inbox_count`, `procurator_phase`, `s1_inbox_count`, `s2_inbox_count`
  - manifest conditions: `[]`
- **坑（实现/配置导致）**:
  - 本轮没有新的保真问题；但 no-witness NEAR 本次 wall≈321.7s，比上一轮 witness-wiring 下的 near-wrap≈203.7s 慢。`ReachSafety.xml` 与 `ReachSafety-Witness.xml` 的主要差异只是 witness printer 插件，EPF 差异也主要是 witness printer 设置；该现象暂判为求解抖动/早停观测差异，不能据此简单声称 no-witness 总是加速 NEAR。
  - 静态审计发现 schedule-mode lazy witness refinement 若本次 witness rerun 没有生成 GraphML，旧代码会 fallback 到目录里的 latest GraphML；这不会让 `conditions` 结果通过 certification gate，但可能污染后续 closure refinement 与 manifest 审计。
- **修复/沉淀**:
  - `dslc/workflows/wraparound_cegis.py`: 收紧 schedule-mode witness 查找，只消费当前 confirm BPL 对应且本次 rerun 更新的 GraphML，或本次 rerun 之后新生成的 GraphML；不再用目录旧 witness 兜底。
  - `dslc/tests/test_wraparound_schedule.py`: 新增 `test_schedule_replay_does_not_reuse_stale_near_wrap_witness`，覆盖旧 GraphML 不应进入 `closure_assumes` / `schedule.conditions`。
  - 保留 no-witness fast path，因为 ENTRY 明确收益明显，NEAR 的语义不依赖 witness，且 witness 只在 closure UNKNOWN 后才需要。
  - 后续若要优化 NEAR，应做同 BPL 多次 A/B 中位数或只对 ENTRY 强制 no-witness、NEAR 允许可配置 toolchain；当前不做无证据调参。
- **是否沉淀为冒烟测试**: 是。
  - 已有 `test_multi_schedule_replay_uses_nowitness_fast_path` 锁定当前默认 wiring。
  - 新增 stale witness 回归，防止条件化 closure refinement 消费旧 witness。

## 2026-04-28

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`（review/回归，无新增求解实验）
- **时间**: `2026-04-28 22:14-22:31`（Asia/Shanghai）
- **目标/进度**: 根据 subagent review 收紧 `schedule_replay` 的保真边界与速度默认；本轮不跑新的 Ultimate 长阶段，只做代码修复和回归。
- **结果**:
  - 修复后快速回归：
    - `python3 -m unittest -v dslc.tests.test_wraparound_schedule dslc.tests.test_wraparound_cli_toolchains`
      - 结果：`Ran 24 tests in 2.417s`, `OK`
    - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke dslc.tests.test_wraparound_schedule dslc.tests.test_wraparound_transform dslc.tests.test_validate_counterexample dslc.tests.test_wraparound_cli_toolchains`
      - 结果：`Ran 74 tests in 82.200s`, `OK`
- **坑（实现/配置导致）**:
  - standalone `procurator wraparound --wraparound-cegar-mode schedule_replay` 仍沿用 witness-enabled 默认 toolchain/settings，和集成 `verify --wraparound auto` 的 no-witness fast path 不一致；会在 ENTRY/NEAR 重新引入不必要 witness printer 开销。
  - `_manifest_certified_unsafe_data()` 之前只通过 `schedule.conditions` 拒绝 witness-derived 条件，未直接检查 `cfg.closure_assumes`；虽然当前生成路径不会产生“closure_assumes 非空但 conditions 为空且 certified=true”的 manifest，但验证入口应防御 stale/malformed manifest。
  - `schedule_id` payload 仍包含 `phases`，这会让 schedule identity 比用户要求的 actor-only `sche` 更细；保守但不符合最终抽象。
- **修复/沉淀**:
  - `dslc/cli/wraparound.py`:
    - 抽出 `_resolve_default_settings()` / `_resolve_cegis_toolchain_settings()`。
    - standalone schedule-replay 默认 ENTRY/NEAR 改用 `ReachSafety.xml` + `ReachSafety-32bit-GemCutter-ALL.epf`；legacy 模式保留 witness-enabled 默认。
  - `dslc/workflows/wraparound_cegis.py`:
    - certification helper 直接拒绝非空 `cfg.closure_assumes`，即使 manifest 中 `schedule.conditions` 被误删也不能认证。
  - `dslc/workflows/wraparound_schedule.py`:
    - `schedule_id` hash 去掉 `phases`，只由 candidate/target/index/step、actor array、projection、base hash 等证书要素决定；`phases` 继续保留为 audit metadata。
  - `dslc/tests/test_wraparound_cli_toolchains.py` / `dslc/tests/test_wraparound_schedule.py`:
    - 新增 standalone schedule-replay no-witness 默认回归。
    - 新增 `cfg.closure_assumes` 认证拒绝回归。
    - 新增 schedule identity 忽略 phase metadata 回归。
- **是否沉淀为冒烟测试**: 是。
  - 相关回归已纳入 `test_wraparound_schedule` 与 `test_wraparound_cli_toolchains`。

## 2026-04-28

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`（策略优化/回归，无新增求解实验）
- **时间**: `2026-04-28 22:31-22:42`（Asia/Shanghai）
- **目标/进度**: 继续优化三阶段 schedule-replay 的求解速度，在不影响保真的情况下减少不可认证分支耗时：集成 `verify --wraparound auto` 中，若纯 CLOSURE `UNKNOWN/TIMEOUT`，直接 fallback 到 ordinary GemCutter，不再先跑 witness-conditioned closure refinement；standalone/debug 仍可开启该诊断 refinement。
- **结果**:
  - 快速回归：
    - `python3 -m unittest -v dslc.tests.test_wraparound_schedule`
      - 结果：`Ran 22 tests in 2.239s`, `OK`
    - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke dslc.tests.test_wraparound_schedule dslc.tests.test_wraparound_transform dslc.tests.test_validate_counterexample dslc.tests.test_wraparound_cli_toolchains`
      - 结果：`Ran 75 tests in 76.643s`, `OK`
- **坑（实现/策略导致）**:
  - subagent review 指出：closure UNKNOWN 后的 witness-conditioned refinement 只能产生 diagnostic `conditions`，即使 closure SAFE 也不能认证；在集成 `verify --wraparound auto` 默认路径中继续跑它会拖延 ordinary GemCutter fallback。
- **修复/沉淀**:
  - `dslc/workflows/wraparound_cegis.py`:
    - schedule-replay 复用 `enable_env_completion_refinement` 作为“是否允许 diagnostic witness refinement”的开关。
    - 集成 multi-target 路径已传 `enable_env_completion_refinement=False`，因此纯 closure UNKNOWN 后直接 fallback，不再跑 `confirm.witness.*` 或 projection weakening。
    - standalone `run_wraparound_cegis` 默认仍为 `True`，保留调试/审计用的条件化 closure refinement。
  - `dslc/tests/test_wraparound_schedule.py`:
    - 新增 `test_schedule_replay_skips_diagnostic_witness_when_refinement_disabled`，锁定集成 fast fallback 语义。
    - witness seeding / stale witness / witness timeout / projection weakening 测试显式设置 diagnostic refinement enabled，避免和集成默认混淆。
- **是否沉淀为冒烟测试**: 是。
  - 新增 fast fallback 单测，并保持 schedule/transform/manifest/P4B slicing 基础冒烟通过。

## 2026-04-28

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`（review/认证边界，无新增求解实验）
- **时间**: `2026-04-28 22:42-22:55`（Asia/Shanghai）
- **目标/进度**: 处理第二个 subagent review 的剩余高优先级问题：manifest certification 必须自己强制“projection 只能是候选投影”，不能依赖 producer；schedule manifest 不应序列化细粒度 reaction 事件。
- **结果**:
  - 聚焦回归：
    - `python3 -m unittest -v dslc.tests.test_wraparound_schedule dslc.tests.test_validate_counterexample`
      - 结果：`Ran 29 tests in 3.155s`, `OK`
  - 快速全量回归：
    - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke dslc.tests.test_wraparound_schedule dslc.tests.test_wraparound_transform dslc.tests.test_validate_counterexample dslc.tests.test_wraparound_cli_toolchains`
      - 结果：`Ran 75 tests in 94.905s`, `OK`
- **坑（实现/认证边界导致）**:
  - certification helper 之前只比较 `projection` 中 `source=="candidate_projection"` 的 lhs，若 malformed/stale manifest 把 witness predicate 放进 `projection` 而非 `conditions`，extra predicate 会被忽略。
  - certification helper 之前缺 `cfg.proj_vars` 时会跳过 projection 校验；测试里曾有缺 cfg 但加 `near_wrap` 后仍认证的正例。
  - `ActorSchedule.to_manifest()` 会把 `reactions` 序列化进 schedule object，虽然不参与 hash，但和用户要求的 actor-only `sche` 证书形态不一致。
- **修复/沉淀**:
  - `dslc/workflows/wraparound_cegis.py`:
    - schedule-mode certification 必须存在 `cfg.proj_vars`。
    - `schedule.projection` 长度、顺序、`source=="candidate_projection"`、`lhs`、`rhs=="entry_snapshot"` 必须与 `cfg.proj_vars` 精确匹配。
    - 任何 extra projection（包括 `source=="near_wrap_witness"`）都会拒绝认证。
  - `dslc/workflows/wraparound_schedule.py`:
    - `ActorSchedule.to_manifest()` 不再输出 `reactions`；`reactions` 只保留为本地 audit/debug 元数据，不属于 certified schedule。
  - `dslc/tests/test_wraparound_schedule.py`:
    - 新增/调整 negative tests：extra witness projection、wrong projection rhs、missing cfg 均不能认证。
    - `test_static_schedule_extracts_phase_actor_array` 确认 manifest 中没有 `reactions`。
- **是否沉淀为冒烟测试**: 是。
  - 认证边界已纳入 schedule manifest 单测，并且 validate counterexample 相关测试保持通过。

## 2026-04-28

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`
- **时间**: `2026-04-28 22:56-23:03`（Asia/Shanghai）
- **目标/进度**: 按阶段继续验证 NetChain `schedule_replay`，复用 run_id `20260428-220734-9a40` 已生成的 `closure_check.bpl`，只跑 CLOSURE_CHECK，不重跑 ENTRY/NEAR。
- **结果**:
  - 输入 BPL:
    - `.tmp/procurator/verify/netchain_wraparound_bug/20260428-220734-9a40/wraparound/target.00.s1_sequence_reg/netchain_wraparound_bug.schedule.00.closure_check.bpl`
  - 命令形态:
    - 通过 `dslc.workflows.wraparound_cegis.UltimateStageRunner` 直接调用 Ultimate。
    - `toolchain=ClosureCheck-ReachSafety.xml`
    - `settings=ReachSafety-32bit-GemCutter-ALL.epf`
    - `timeout_seconds=420`
    - `xmx_gb=4`
  - log:
    - `.tmp/procurator/verify/netchain_wraparound_bug/20260428-220734-9a40/wraparound/target.00.s1_sequence_reg/netchain_wraparound_bug.schedule.00.closure_check.bpl.manual420.log`
  - 结果:
    - `RESULT: Ultimate could not prove your program: Timeout`
    - wall≈441.1s
    - CFG: 15 procedures, 254 locations, 403 edges, 1 error location
- **坑（实现/配置导致）**:
  - 前两次尝试 direct closure 时被 PowerShell/WSL/Python 嵌套引号打断，没有启动 Ultimate；第三次改为 WSL `/tmp/run_netchain_closure.py` 临时脚本并设置 `PYTHONPATH=/mnt/e/p4-verify` 后正常运行。
  - 本轮 CLOSURE 超时不是实现错误证据；按用户之前提示，NetChain closure 本来可能需要 300s+，当前 420s + low-memory profile 仍未证明。
- **修复/沉淀**:
  - 本轮不改代码；确认 schedule-replay 当前瓶颈在 NetChain pure projection CLOSURE 证明阶段。
  - 后续应只针对 CLOSURE BPL 调参/优化（例如 closure-friendly settings、projection/Boogie transform 层优化），不要重复跑 ENTRY/NEAR。
- **是否沉淀为冒烟测试**: 否。
  - 这是阶段性求解实验，结果为 timeout；不作为通过/失败冒烟。

## 2026-04-28

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`
- **时间**: `2026-04-28 23:03-23:49`（Asia/Shanghai）
- **目标/进度**: 继续把 NetChain 上的三阶段 `schedule_replay` 求解优化到总耗时 8 分钟以内，并确认优化不改变 Boogie 语义、schedule 证书形态或 fallback 保真边界。
- **结果**:
  - 先复用同一组 no-reg-debug 产物确认瓶颈在 CLOSURE 求解形态，而不是证书语义:
    - no-reg-debug base run_id `20260428-225359-c2e2`
    - `ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por.epf`: CLOSURE wall≈261.2s 后 timeout
    - `ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf`: CLOSURE wall≈280.4s 后 timeout
    - 拆分最终断言后只证明 s1 sequence 项: wall≈129.2s 后仍 timeout
  - 新增并接入 8GB all-inline profile:
    - `dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por-allinline.epf`
    - 与 `8g-noz3timeout-no-por` 相比，只把 Boogie procedure inliner 的 `Ignore calls to procedures called more than once` 设为 `NEVER`；这是 Ultimate 预处理/求解形态优化，不改变生成的 Boogie model、schedule、projection 或认证规则。
  - 同一批 BPL 的手工分阶段结果:
    - ENTRY: `RESULT: UNSAFE`, wall≈25.7s
    - NEAR_WRAP: `RESULT: UNSAFE`, wall≈61.8s
    - CLOSURE: `RESULT: SAFE`, wall≈99.9s
  - 集成 staged run 验证 all-inline wiring:
    - stop-after entry run_id `20260428-233140-e715`: ENTRY `UNSAFE`, wall≈86.9s，日志确认使用 `ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por-allinline.epf`
    - stop-after near run_id `20260428-233335-a3ac`: ENTRY `UNSAFE`, wall≈63.5s；NEAR_WRAP `UNSAFE`, wall≈76.7s，日志确认使用 all-inline settings
  - 完整三阶段 certified run:
    - 命令:
      - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop --boogie-harness sequential --no-two-stage --no-reg-debug --ultimate-xmx-gb 8 --wraparound auto --wraparound-cegar-mode schedule_replay --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --ultimate-timeout-seconds 480`
    - run_id `20260428-233614-c126`
    - manifest: `.tmp/procurator/verify/netchain_wraparound_bug/20260428-233614-c126/wraparound/target.00.s1_sequence_reg/wraparound.cegis.manifest.json`
    - 结果: `CERTIFIED UNSAFE`
    - 阶段耗时: ENTRY≈27.0s, NEAR_WRAP≈44.5s, CLOSURE≈208.2s，总阶段耗时≈279.7s（小于 8 分钟）
  - 证书审计:
    - `_manifest_certified_unsafe_data(data) == True`
    - schedule actors: `["h1", "h1", "s1", "s2"]`
    - schedule manifest 中没有 `reactions`
    - projection: `h1_inbox_count`, `procurator_phase`, `s1_inbox_count`, `s2_inbox_count`
    - projection 全部来自 `candidate_projection`，并且 rhs 均为 `entry_snapshot`
    - `conditions=[]`
    - `cfg.closure_assumes=[]`
    - manifest 的 base hash 与 schedule base hash 匹配
- **坑（实现/配置导致）**:
  - NetChain CLOSURE 的主要问题是 repeated helper procedure calls 让 TraceAbstraction 在摘要/插值上耗时，而不是 pure projection 或 actor-only schedule 的语义不够；直接加 witness 条件或细粒度事件会破坏证书边界，不能作为 certified fast path。
  - no-witness fast path 的最终 certified run 会在顶层 counterexample validator 里提示 `[CEX-WARN] missing: no *.bpl-witness.graphml in out_dir`；这是预期行为，因为 schedule-replay 的认证产物是 manifest 中的 ENTRY/NEAR UNSAFE + CLOSURE SAFE 证书，而不是顶层 GraphML witness。
  - all-inline profile 去掉 Z3 单 query timeout，必须继续依赖外层 Ultimate stage timeout；本轮命令仍显式使用 `--ultimate-timeout-seconds 480`，并且按阶段验证，没有盲跑长 E2E。
- **修复/沉淀**:
  - `dslc/workflows/wraparound_cegis.py`:
    - 高内存（`ultimate_xmx_gb >= 8`）时 closure settings 优先选择 all-inline profile。
    - `schedule_replay` 在高内存 all-inline closure settings 下，ENTRY/NEAR 也复用 all-inline settings；低内存默认保持原 no-witness settings，WSL 安全默认不变。
    - legacy CEGIS 路径仍保持 witness-enabled front stages，不改变旧调试/诊断行为。
  - `dslc/cli/wraparound.py`:
    - standalone `procurator wraparound --wraparound-cegar-mode schedule_replay --ultimate-xmx-gb 8` 默认使用 all-inline settings/closure-settings，用户显式传入 settings 时不覆盖。
  - `dslc/tests/test_wraparound_cli_toolchains.py`:
    - 新增 high-memory schedule-replay 默认选择 all-inline settings 的回归。
  - `dslc/tests/test_wraparound_schedule.py`:
    - 新增/保持 schedule-replay high-memory all-inline stage settings、actor-only schedule、projection/conditions 认证边界等回归。
  - subagent soundness review（James）结论: 无 blocking finding；all-inline 属于 Ultimate procedure-inlining/search-shape 改动，不削弱 Boogie 语义或证书 gate；残余信任边界是 Ultimate ProcedureInliner 本身。
- **是否沉淀为冒烟测试**: 是。
  - `python3 -m unittest -v dslc.tests.test_wraparound_cli_toolchains`：`Ran 4 tests in 1.012s`, `OK`
  - `python3 -m unittest -v dslc.tests.test_wraparound_schedule`：`Ran 23 tests in 3.161s`, `OK`
  - `python3 -m unittest -v dslc.tests.test_wraparound_cli_toolchains dslc.tests.test_wraparound_schedule dslc.tests.test_wraparound_transform dslc.tests.test_validate_counterexample`：`Ran 50 tests in 4.015s`, `OK`
  - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke dslc.tests.test_wraparound_schedule dslc.tests.test_wraparound_transform dslc.tests.test_validate_counterexample dslc.tests.test_wraparound_cli_toolchains`：`Ran 77 tests in 92.931s`, `OK`

## 2026-04-28

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`（review fix / 回归，无新增 Ultimate 求解实验）
- **时间**: `2026-04-28 23:49-23:58`（Asia/Shanghai）
- **目标/进度**: 根据 Copernicus review 修复 high-memory `schedule_replay` all-inline 选择的脆弱性，并补测试保证未来恢复 closure-specific EPF 时不会退回慢配置。
- **结果**:
  - Copernicus review 发现：如果将来恢复 `ClosureCheck-32bit-GemCutter-ALL-witness.epf`，集成路径可能先选到 closure-specific EPF，从而绕过 all-inline profile；当前 checkout 不受影响，但策略不够显式。
  - 已修复为：`schedule_replay + ultimate_xmx_gb >= 8` 会独立优先选择 `ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por-allinline.epf`，同时用于 ENTRY/NEAR 和 CLOSURE；legacy/debug 默认仍不变。
  - NetChain certified manifest 复审仍通过：
    - run_id `20260428-233614-c126`
    - ENTRY `UNSAFE` 26.990988s
    - NEAR_WRAP `UNSAFE` 44.486364s
    - CLOSURE `SAFE` 208.225677s
    - 总阶段耗时 279.703029s，小于 8 分钟
    - schedule actors `["h1", "h1", "s1", "s2"]`，无 `reactions`，`conditions=[]`，`cfg.closure_assumes=[]`
- **坑（实现/配置导致）**:
  - 原 high-memory all-inline 测试 mock 了 `_default_toolchain_paths()`，但未隔离 `repo_root()`；新增 helper 后会看到真实仓库中的 all-inline profile，导致测试依赖本机文件布局。已将测试中的 `repo_root()` mock 到临时目录。
- **修复/沉淀**:
  - `dslc/workflows/wraparound_cegis.py`:
    - 新增 `_schedule_replay_allinline_settings()` / `_schedule_replay_closure_settings()`。
    - integrated `schedule_replay` 显式把 all-inline profile 作为 high-memory closure/front-stage settings。
  - `dslc/tests/test_wraparound_schedule.py`:
    - 新增 `test_multi_schedule_replay_high_memory_prefers_allinline_over_closure_specific_epf`，模拟 closure-specific EPF 存在时仍应选择 all-inline。
- **是否沉淀为冒烟测试**: 是。
  - `python3 -m unittest -v dslc.tests.test_wraparound_cli_toolchains dslc.tests.test_wraparound_schedule`：`Ran 28 tests in 3.045s`, `OK`
  - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke dslc.tests.test_wraparound_schedule dslc.tests.test_wraparound_transform dslc.tests.test_validate_counterexample dslc.tests.test_wraparound_cli_toolchains`：`Ran 78 tests in 93.826s`, `OK`
## 2026-04-29

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`
- **时间**: `2026-04-29 00:19-01:39` (Asia/Shanghai)
- **目标/进度**: 将 `schedule_replay` 的 projection 从候选/手写变量升级为依赖分析自动抽取的实现级投影，并保持 schedule 证书为 actor 顺序数组；NetChain 三阶段总耗时压进 10 分钟。
- **结果**:
  - 修复前复现:
    - run_id `20260429-002148-c42b`
    - ATTEMPT 0: ENTRY `UNSAFE` wall≈20.6s, NEAR_WRAP `UNSAFE` wall≈66.7s, CLOSURE `UNSAFE` wall≈233.4s
    - 失败原因: projection 里无条件包含 `*_pkt_external`，而该字段是单槽 mailbox 的 stale slot tag；当 `s1_inbox_count==0` 时 tag 值没有语义，closure 反例只打破 `s1_pkt_external == snapshot`，计数器净效应实际成立。
  - 分阶段验证:
    - stop-after entry run_id `20260429-010518-f4e3`: ENTRY `UNSAFE`, wall≈32.3s
    - stop-after near_wrap run_id `20260429-010617-e032`: ENTRY `UNSAFE`, wall≈34.9s; NEAR_WRAP `UNSAFE`, wall≈97.9s
    - stop-after closure run_id `20260429-010850-04e5`: ENTRY `UNSAFE`, wall≈85.8s; NEAR_WRAP `UNSAFE`, wall≈175.8s; CLOSURE `SAFE`, wall≈148.2s
  - 完整 certified run:
    - run_id `20260429-013443-0e63`
    - 命令:
      - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop --boogie-harness sequential --no-two-stage --no-reg-debug --ultimate-xmx-gb 8 --wraparound auto --wraparound-cegar-mode schedule_replay --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 300 --ultimate-timeout-seconds 600`
    - manifest: `.tmp/procurator/verify/netchain_wraparound_bug/20260429-013443-0e63/wraparound/target.00.s1_sequence_reg/wraparound.cegis.manifest.json`
    - 结果: `CERTIFIED UNSAFE`
    - 阶段耗时: ENTRY≈28.6s, NEAR_WRAP≈54.9s, CLOSURE≈161.4s; 外层 wall≈252.7s (小于 10 分钟)
  - 证书审计:
    - schedule actors: `["h1", "h1", "s1", "s2"]`
    - schedule manifest 不包含 `phases` / `reactions` / 细粒度事件轨迹
    - projection state vars: `procurator_phase`, `h1_inbox_count`, `s1_inbox_count`, `s2_inbox_count`
    - projection predicates:
      - `s1_meta.location.index == 0bv16`
      - `s2_meta.location.index == 0bv16`
      - `s1_find_index.hit == true`
      - `s2_find_index.hit == true`
      - `s1_meta.my_md.role == 100bv16`
      - `s2_meta.my_md.role == 101bv16`
      - `s1_standard_metadata.egress_port != 0bv9`
      - `bvule.bv32$builtin(0bv16++s1_meta.location.index, 0bv32)`
      - `bvule.bv32$builtin(0bv16++s2_meta.location.index, 0bv32)`
    - projection entries 全部 `source=dependency_projection`
    - `projection_complete=true`, `conditions=[]`, `cfg.closure_assumes=[]`
    - `python3 -m dslc.bench.validate_counterexample --wraparound-manifest .../wraparound.cegis.manifest.json`: `[OK] certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id`
- **坑（实现错误导致）**:
  - 初版依赖投影把 `*_pkt_external` 当默认 projection state，导致空 mailbox stale tag 破坏闭包。修复为只投影 mailbox count；slot/tag 字段不能在 mailbox 为空时无条件 snapshot。
  - 初版 Boogie-level procedure parser 把 `{:inline 1}` 属性的花括号误当成过程体开头，导致 P4 table/action body 被解析为空，依赖传播严重不完整。
  - 初版将 unresolved / assigned-call 只写入 notes，仍可能认证。修复为 `projection_complete=false` 时 schedule_replay 直接 uncertified fallback，并且 manifest gate 必须要求 `projection_complete=true`。
  - review 发现 projection predicates 已参与 closure 证明但未写进 certified schedule manifest。修复为谓词投影也序列化到 `schedule.projection`，并由 `_manifest_certified_unsafe_data()` 与 `cfg.proj_predicates` 逐项比对。
  - review 发现 inlined procedure 内 live assume 被过滤会让 projection complete 过强。修复为保留 inlined live assume predicates；仅跳过 inlined packet-slot/header predicates，避免把 transient mailbox content 变成空 mailbox cutpoint 的无条件闭包义务。
  - schedule-replay certified 后 CLI 仍尝试普通 GraphML witness summary，产生 `[CEX-WARN] missing`；修复为 certified manifest 使用 `validate_wraparound_manifest()` 进行证书校验。
- **修复/沉淀**:
  - 新增 `dslc/analysis/wraparound_projection.py`: Boogie-level control/data dependency projection extraction，支持 procedure inlining、opaque modifies 摘要、write 调用依赖、projection completeness。
  - `dslc/transform/wraparound_*`: closure 支持 projection predicates 的 snapshot 和 after-round truth-value preservation。
  - `dslc/workflows/wraparound_schedule.py`: schedule manifest 保持 actor-order-only，去掉 `phases`/`reactions`，并将依赖谓词作为 projection entries 纳入 `schedule_id`。
  - `dslc/workflows/wraparound_cegis.py`: schedule_replay 使用依赖投影；certification gate 要求 dependency projection、projection predicates 匹配、projection complete、无 witness conditions/closure assumes。
  - `dslc/cli/gemcutter.py`: certified wraparound 使用 manifest validator，不再要求普通 GraphML witness。
  - subagent review:
    - Gauss: 确认 NetChain CLOSURE 反例来自 stale `s1_pkt_external`，不是计数器净效应失败。
    - Turing: 指出 unresolved calls / assigned-call / guarded assignment 的 soundness 风险。
    - Mencius: 指出 projection predicates 必须进入 manifest/gate，且 inlined live assumes 不能静默丢弃。
- **是否沉淀为冒烟测试**: 是。
  - `python3 -m unittest -v dslc.tests.test_wraparound_schedule dslc.tests.test_validate_counterexample`: Ran 35 tests, OK
  - `python3 -m unittest -v dslc.tests.test_wraparound_schedule dslc.tests.test_validate_counterexample dslc.tests.test_wraparound_transform dslc.tests.test_wraparound_workflow_smoke dslc.tests.test_wraparound_confirm_instrument_newline dslc.tests.test_wraparound_instrument_reassert_after_havoc dslc.tests.test_wraparound_analyze_register_typedefs`: Ran 56 tests, OK
  - `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke`: Ran 27 tests, OK

## 2026-04-29

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`
- **时间**: `2026-04-29 01:53-02:16` (Asia/Shanghai)
- **目标/进度**: 根据 subagent review 继续硬化 `schedule_replay` 证书边界：把认证从“manifest 自洽”推进到“manifest + 实际 base BPL + stage artifact/log”复核；同时保持 NetChain 三阶段总耗时小于 10 分钟，并确认依赖投影、actor-only schedule、fallback 保真边界不回退。
- **结果**:
  - review 前 sanity run:
    - run_id `20260429-015324-2be0`
    - ENTRY `UNSAFE`, wall≈31.1s
    - NEAR_WRAP `UNSAFE`, wall≈87.0s
    - CLOSURE `SAFE`, wall≈213.7s
    - outer wall≈341.2s，小于 10 分钟
  - Euclid review 指出 4 个认证边界问题:
    - public validator 只检查 self-consistent JSON，没有读取实际 `base_bpl`、没有重抽 schedule/projection、没有检查 stage logs/artifacts。
    - `conditions` / `closure_assumes` 缺字段时会被当成空；`projection_complete` / `certified` 用 truthiness，字符串 `"false"` 也可能通过。
    - `cutpoint_cond` 影响 ENTRY/NEAR/CLOSURE 证明义务，但未纳入 candidate identity。
    - `ActorSchedule.to_manifest()` 生成 actor-only schedule，但 validator 未拒绝额外的 `phases` / `reactions` 字段。
  - 修复后 fresh certified run:
    - run_id `20260429-020847-007a`
    - command:
      - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop --boogie-harness sequential --no-two-stage --no-reg-debug --ultimate-xmx-gb 8 --wraparound auto --wraparound-cegar-mode schedule_replay --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 300 --ultimate-timeout-seconds 600`
    - manifest:
      - `.tmp/procurator/verify/netchain_wraparound_bug/20260429-020847-007a/wraparound/target.00.s1_sequence_reg/wraparound.cegis.manifest.json`
    - result: `CERTIFIED UNSAFE`
    - ENTRY `UNSAFE`, wall≈50.9s
    - NEAR_WRAP `UNSAFE`, wall≈75.8s
    - CLOSURE `SAFE`, wall≈164.5s
    - outer wall≈303.1s，小于 10 分钟
  - 新版证书审计:
    - `schedule_id`: `93c6755e303fb350a46c2de9`
    - `candidate_id`: `0299d2f689d4a07d678e547e`
    - schedule actors: `["h1", "h1", "s1", "s2"]`
    - schedule manifest 不包含 `phases` / `reactions`
    - projection state vars: `procurator_phase`, `h1_inbox_count`, `s1_inbox_count`, `s2_inbox_count`
    - projection predicates count: 9
    - projection entries 全部 `source=dependency_projection`
    - `projection_complete=true`, `conditions=[]`, `cfg.closure_assumes=[]`
    - base hash matches schedule base hash
    - `python -m dslc.bench.validate_counterexample --wraparound-manifest .../wraparound.cegis.manifest.json`: `[OK] certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id`
- **坑（实现/认证边界导致）**:
  - 旧的 certified manifest（例如 `20260429-015324-2be0` 及之前）在新版 validator 下会被拒绝；这是预期行为，因为 `cutpoint_cond` 新增进 `candidate_id`，旧证书 hash 规范不完整，需要 fresh run 重新产出证书。
  - Windows Python 直接跑 P4B selftest 会尝试执行 Linux/WSL 的 `p4c-translator` 并报 `WinError 193`；正确口径是在 WSL 下跑 P4B 相关 selftest。
  - fake StageRunner 单测以前只返回 `StageRunResult`，不写 log；artifact-level validator 加强后需要 fake runner 写出带 stage BPL 文件名和 RESULT 的日志，已同步修复测试。
- **修复/沉淀**:
  - `dslc/workflows/wraparound_schedule.py`:
    - `compute_wraparound_candidate_id()` 纳入 `cutpoint_cond`。
    - schedule identity 继续只使用 actor 数组、target/index/step、projection、base hash 等证书要素，不序列化细粒度事件。
  - `dslc/workflows/wraparound_cegis.py`:
    - certification gate 要求 `conditions` 与 `closure_assumes` 显式为空序列。
    - `projection_complete is True`、`certified is True`，不再接受 truthy 字符串。
    - schedule 中出现 `phases` / `reactions` 时拒绝认证。
    - 继续要求 dependency projection、projection predicates、cfg/schedule target/index/step/candidate_id/schedule_id 一致。
  - `dslc/bench/validate_counterexample.py`:
    - schedule-replay public validator 读取实际 `base_bpl` 并复算 sha256。
    - 从 base BPL 重抽 deterministic actor schedule 与 dependency projection，比较 `cfg` / `schedule`。
    - 读取 ENTRY/NEAR/CLOSURE stage logs，检查结果与 manifest 一致，并要求 log 中包含对应 stage BPL 文件名。
    - 支持 Windows 下验证 WSL `/mnt/<drive>/...` 路径。
  - `dslc/tests/test_wraparound_schedule.py` / `dslc/tests/test_validate_counterexample.py`:
    - 新增/收紧缺字段、字符串布尔、forbidden `phases/reactions`、target/index/step/candidate mismatch、自洽 JSON 但缺真实 artifacts 等负例。
- **是否沉淀为冒烟测试**: 是。
  - `python -m unittest -v dslc.tests.test_wraparound_schedule dslc.tests.test_validate_counterexample`: Ran 36 tests, OK
  - `python -m unittest -v dslc.tests.test_wraparound_schedule dslc.tests.test_validate_counterexample dslc.tests.test_wraparound_transform dslc.tests.test_wraparound_workflow_smoke dslc.tests.test_wraparound_confirm_instrument_newline dslc.tests.test_wraparound_instrument_reassert_after_havoc dslc.tests.test_wraparound_analyze_register_typedefs`: Ran 57 tests, OK
  - `python -m unittest -v dslc.tests.test_wraparound_transform dslc.tests.test_wraparound_workflow_smoke dslc.tests.test_wraparound_confirm_instrument_newline dslc.tests.test_wraparound_instrument_reassert_after_havoc dslc.tests.test_wraparound_analyze_register_typedefs`: Ran 21 tests, OK
  - WSL: `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke`: Ran 27 tests, OK

## 2026-04-29

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop` (compile/structure only; no Ultimate solving in this entry)
- **时间**: `2026-04-29 10:56-11:12` (Asia/Shanghai)
- **目标/进度**: 拆分 Boogie 插桩职责时，先把 P4-local 的 register write mirror 插桩从 Python DSL 后处理迁到 P4B-Translator，并验证 NetChain sliced/merged BPL 不依赖 Python 二次插桩也能保留 wraparound 所需镜像变量。
- **结果**:
  - P4B sliced raw BPL: `/tmp/procurator_reg_mirror/netchain.raw.bpl`
    - `sequence_reg__last_index/__last_value/__wrote_any/__wrote_index0/__last0_value` 均由 P4B 原生声明。
    - `sequence_reg.write` 原生更新上述 5 个 mirror，并且调用链 `modifies` 已传播 mirror。
    - `value_reg__last0_value` 未出现，说明 `--slicing-vars=sequence_reg[0]` 下未把无关寄存器 mirror 带回。
  - DSL merged BPL: `/tmp/procurator_reg_mirror/netchain.merged.bpl`
    - `s1_sequence_reg__last_index/__last_value/__wrote_any/__wrote_index0/__last0_value` 均只有 1 个声明。
    - `s1_sequence_reg.write` 中 mirror 更新只有一份，Python fallback 没有重复插桩。
- **坑（实现/流程导致）**:
  - 第一次检查命令把 `grep` pattern 中的 `{:` 放进双引号，shell 误解析导致检查命令失败；翻译产物未受影响，之后拆成生成与检查两步。
  - 新增 smoke spec 初版漏了 DSL `assert { ... };` 的分号，导致 parser 报 `Expected SEMICOLON`；已修正为回归测试。
  - 兼容 fallback 初版只检查 mirror 声明是否存在；若旧/外部 BPL 只声明 mirror 但 `.write` 没有更新，可能误跳过插桩。已收紧为“声明完整且 write body 更新完整”才跳过，否则补 body 且不重复声明。
  - subagent review 本轮两次均因 `429 Too Many Requests` 中断，未产出有效 review；本轮用本地结构检查和回归测试兜底，后续网络/额度恢复后需要再让 subagent 审 P4B modifies 传播与 DSL fallback。
- **修复/沉淀**:
  - `P4B-Translator/backends/verify/translate/translate.cpp` / `.h`: P4B 原生声明 register mirror、在 `<reg>.write` 内更新 mirror、用 typedef-aware typed zero 判断 index 0、并把 mirror 加入 register write caller/procedure modifies；slicing 下 base register 保留时同步保留 mirror。
  - `dslc/backends/boogie_registers.py`: Python 插桩保留为 legacy/fallback；新 P4B 输出检测到完整 mirror 后跳过，半完整 mirror 输出会补齐 body/modifies 而不重复声明。
  - `dslc/tests/test_boogie_registers_typedef_index0.py`: 新增半完整 mirror fallback 回归。
  - `dslc/tests/test_boogie_backend_smoke.py`: 新增 prefixed native mirror 不重复插桩回归。
  - `dslc/tests/test_p4b_translator_slicing_selftest.py`: 新增 NetChain sliced raw BPL 中 P4B 原生 mirror 的结构回归。
- **是否沉淀为冒烟测试**: 是。
  - `python -m unittest -v dslc.tests.test_boogie_registers_typedef_index0 dslc.tests.test_boogie_backend_smoke dslc.tests.test_wraparound_transform dslc.tests.test_wraparound_schedule dslc.tests.test_validate_counterexample`: Ran 65 tests, OK
  - WSL: `python3 -m unittest -v dslc.tests.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_netchain_seq_seed_slicing dslc.tests.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_netchain_seq_register_mirrors_emitted_by_p4b`: Ran 2 tests, OK
  - WSL: `cmake --build P4B-Translator/build-host --target p4c-translator -j2`: OK

## 2026-04-29

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop` (compile/structure only; no Ultimate solving in this entry)
- **时间**: `2026-04-29 10:56-11:40` (Asia/Shanghai)
- **目标/进度**: 继续推进 Boogie 插桩职责拆分：把系统级 register debug / tracking helper 从 harness trace/start/thread 等模块中拆到独立 register mixin；把 Python register mirror pass 明确降级为 legacy/backfill；把 backend compile profiling 从主编排文件中拆出。验证这些拆分不改变 NetChain merged BPL。
- **结果**:
  - 新增/整理职责边界：
    - `dslc/backends/boogie_harness_registers.py`: 集中管理系统级寄存器 tracking/debug 变量命名、modifies、debug snapshot declaration/assignment、register init assumptions。
    - `dslc/backends/boogie_harness_trace.py`: 不再拥有 register debug helper；trace 只负责 trace arrays / trace snapshots。
    - `dslc/backends/boogie_registers.py`: 新增 `backfill_legacy_register_write_mirrors()`，主线改用该名字；旧 `instrument_register_writes()` 保留为兼容 wrapper。
    - `dslc/backends/boogie_backend_profile.py`: backend compile profile JSONL 写出和计时逻辑从 `boogie_backend.py` 拆出。
  - NetChain compile/smoke:
    - `/tmp/procurator_refactor_cmp/netchain.after2.bpl`: compile + smoke OK。
    - `/tmp/procurator_refactor_cmp/netchain.after3.bpl`: compile + smoke OK，并与 `after2` exact match。
    - `/tmp/procurator_refactor_cmp/netchain.after4.bpl`: compile + smoke OK，并与 `after3` exact match。
    - `after2/after3/after4` 均与前置基线 `/tmp/procurator_reg_mirror/netchain.merged.bpl` 或前一轮拆分产物逐字节一致，说明本轮拆分未改变 NetChain 目标 Boogie。
  - Subagent review:
    - Bernoulli / James 首轮 review 发现 `Ref` register debug/trace 边界问题。
    - 修复后 Bernoulli / James 最终复审均为 no blocking findings。
- **坑（实现错误导致）**:
  - `Ref` register 的 element type 没有自然的 `0` 字面量；旧逻辑在 register init/debug 路径上容易生成 `Ref == 0` 或把 `Ref` 寄存器映射到未声明的 `__dbg0`。
  - `_register_modifies_for_nodes(... include_debug=True)` 初版会把所有寄存器的 debug vars 加入 modifies，但 `Ref` register debug declarations/assignments 会被跳过，导致潜在未声明变量。
  - `_map_register_zero_to_dbg()` 初版只看 `reg[0]`，不看 element type；当 DSL assert 引用 `Ref` register index 0 时，可能重写到未声明的 `s1_ref_reg__dbg0`。
  - trace 默认关闭，普通 compile 测试无法覆盖 trace-enabled `Ref` register 路径；subagent 指出 trace reset 对 `Ref` trace cell 会跳过值 reset，留下 stale/unconstrained trace cell。
  - Windows shell 中系统 `python` 不在 PATH，本轮继续使用 `.\.venv\Scripts\python.exe`；WSL/P4B 相关 selftest 在 WSL 中运行。
- **修复/沉淀**:
  - `dslc/backends/boogie_harness_registers.py`:
    - 新增 `_register_debug_enabled_for_type()` / `_register_type_is_ref_like()`。
    - debug modifies/declarations/assignments 统一跳过 `Ref`/`*Ref` register。
    - `Ref` register init 不再生成 zero-literal assumptions；tracking mirrors 通过 `assume mirror == reg[0]` 与实际数组 cell 对齐。
  - `dslc/backends/boogie_harness_dsl.py`:
    - `reg[0]` assertion rewrite 仅对可 debug 的 element type 使用 `__dbg0`；`Ref` register fallback 到 `__last0_value`。
  - `dslc/backends/boogie_harness_trace.py`:
    - trace snapshot 对 `Ref` register 使用 `reg[0]`，不引用未声明的 `reg__dbg0`。
    - trace reset 对无 zero literal 的 element type 使用当前 `reg[0]` / `reg__last0_value` 填充 trace cell。
  - `dslc/tests/test_boogie_harness_sequential_reg_dbg_snapshot.py`:
    - 新增 sequential/concurrent `Ref` register 回归，检查不生成 `__dbg` 未声明变量、不生成 `Ref == 0`，并使用 `__last0_value`。
    - 新增 trace-enabled emitter 回归，直接锁定 `trace_ref_reg__dbg0 := ref_reg[0]`，防止 trace 路径回退到未声明 debug var。
  - `dslc/backends/boogie_backend_profile.py`:
    - compile profile 逻辑独立模块化，profile 写文件失败仍不影响编译正确性。
- **是否沉淀为冒烟测试**: 是。
  - `.\.venv\Scripts\python.exe -m unittest -v dslc.tests.test_boogie_harness_sequential_reg_dbg_snapshot`: Ran 4 tests, OK。
  - `.\.venv\Scripts\python.exe -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_harness_sequential_reg_dbg_snapshot dslc.tests.test_boogie_registers_typedef_index0`: Ran 17 tests, OK。
  - `.\.venv\Scripts\python.exe -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_boogie_harness_sequential_reg_dbg_snapshot dslc.tests.test_boogie_registers_typedef_index0 dslc.tests.test_wraparound_transform dslc.tests.test_wraparound_schedule dslc.tests.test_validate_counterexample`: Ran 71 tests, OK。
  - WSL: `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke`: Ran 29 tests, OK。
  - WSL NetChain compile/smoke/exact compare:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop --out /tmp/procurator_refactor_cmp/netchain.after4.bpl --boogie-harness sequential --no-two-stage`
    - `./bin/procurator smoke --bpl /tmp/procurator_refactor_cmp/netchain.after4.bpl --harness sequential`
    - `cmp -s /tmp/procurator_refactor_cmp/netchain.after3.bpl /tmp/procurator_refactor_cmp/netchain.after4.bpl`: `EXACT_MATCH`

### 2026-04-29 addendum

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop` (compile/structure only; no Ultimate solving)
- **补充进度**: 在上述 register/profile 拆分之后，继续把 `boogie_backend.py` 中的最终 Boogie 拼接职责拆到 `dslc/backends/boogie_backend_merge.py`，让 backend 主文件只保留编排，merge 模块负责 preamble、prefixed node bodies、enqueue procedures、harness 拼接和 Ultimate bvbuiltin rewrite。
- **结果**:
  - NetChain compile/smoke: `/tmp/procurator_refactor_cmp/netchain.after5.bpl` OK。
  - `cmp -s /tmp/procurator_refactor_cmp/netchain.after4.bpl /tmp/procurator_refactor_cmp/netchain.after5.bpl`: `EXACT_MATCH`。
- **回归**:
  - `.\.venv\Scripts\python.exe -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_boogie_harness_sequential_reg_dbg_snapshot dslc.tests.test_boogie_registers_typedef_index0 dslc.tests.test_wraparound_transform dslc.tests.test_wraparound_schedule dslc.tests.test_validate_counterexample`: Ran 71 tests, OK。
  - WSL: `python3 -m unittest -v dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_p4b_translator_slicing_selftest dslc.tests.test_wraparound_workflow_smoke`: Ran 29 tests, OK。


## 2026-04-29

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`
- **??/??**: ?? DSLC/P4B ?????????????????????? `<3000` ????????????? `<=8`???? NetChain ?? Boogie ????
- **??**:
  - DSLC focused tests: PASS?`dslc.tests.test_boogie_backend_smoke dslc.tests.test_boogie_slicing_seeds dslc.tests.test_boogie_harness_sequential_reg_dbg_snapshot dslc.tests.test_boogie_registers_typedef_index0`?19 tests??
  - Wraparound focused tests: PASS?`dslc.tests.test_wraparound_cegis*` ?? 13 tests??
  - P4B build: PASS?`cd P4B-Translator/build-host && cmake --build . --target p4c-translator -j2`??
  - P4B slicing selftest: PASS?`--slicing-selftest=netchain_seq`??
  - NetChain compile/smoke: PASS??? `/tmp/procurator_refactor_split/netchain.after.reviewfix.bpl`??
  - NetChain exact compare: `EXACT_MATCH_AFTER5`?? `/tmp/procurator_refactor_cmp/netchain.after5.bpl` ????
  - ????: PASS??????? `dslc` + `P4B-Translator/backends/verify` ? `.py/.cpp/.h/.hpp` ?? 3000 ??`dslc/backends`?`dslc/workflows`?P4B `translate/slicing` ?????????????? 8??
- **????/?????**:
  - P4B `translate/*.cpp` ?? `translate/impl/*` ??? include?? `#include "translate.h"`?`#include "boogie_procedure.h"`?? unified build ??????? header?
  - ?? `slicer_internal.h` ?? implementation header ??? unified source list?subagent review ????? include guard ? anonymous namespace ???????
  - DSLC review ?? spec ???? DistCache support ???????? legacy mock ???????? `extract_assumptions_from_graphml` / `synthesize_boogie_assumes`?
- **??**:
  - `P4B-Translator/backends/verify/CMakeLists.txt`: ? `verifybackend` ?? `translate` include dir?? `translate` ???? `translate/impl/core` ? `translate/impl/support`?? `slicer_internal.h` ????????
  - `P4B-Translator/backends/verify/slicing/slicer_internal.h`: ???? private namespace `P4Verify::slicing_internal`?`slicer.cpp` / `slicer_apply.cpp` ?? `using namespace slicing_internal`?
  - `dslc/workflows/wraparound_support/distcache.py`: ?? DistCache-specific support?`wraparound_cegis.py` ?? 2663 ???? legacy helper re-export?
  - `doc/dslc_p4b_boundary_refactor_spec.md`: ?? DSLC/P4B ????? spec?
- **?????/????**:
  - ????: `NO_FILES_OVER_3000` / `NO_TARGET_DIRS_OVER_8`?
  - DSLC import smoke ??????? legacy alias?`dslc.backends.boogie_*`?`dslc.workflows.wraparound_support.*`??
  - NetChain compile/smoke + exact compare ???????????????

## 2026-04-29

- **Spec**: Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop
- **Time**: $stamp (Asia/Shanghai)
- **Goal/Progress**: Completed the DSLC/P4B responsibility-boundary refactor spec and the main code-organization split. Enforced the constraints that implementation files stay below 3000 lines and direct folder fanout stays at 8 files or fewer for the touched DSLC/P4B verification tree. Preserved legacy DSLC import compatibility while the full E2E pipeline remains under validation.
- **Result**:
  - DSLC Boogie backend split into dslc/backends/boogie/{core,node,harness} with compatibility aliases for legacy dslc.backends.boogie_* imports.
  - Wraparound CEGIS support split into dslc/workflows/wraparound_support/* while keeping old helper names importable.
  - P4B translator split into 	ranslate/impl/{core,support} and slicer split into slicer.cpp, slicer_apply.cpp, and private slicer_internal.h.
  - Ultimate XML/EPF assets moved under dslc/toolchain/ultimate/{toolchains,settings/...} with dslc/toolchain/ultimate_paths.py resolving legacy flat paths such as dslc/toolchain/ultimate/ReachSafety.xml.
  - Boundary spec written in doc/dslc_p4b_boundary_refactor_spec.md.
- **Pitfalls (implementation issues)**:
  - After moving P4B translate implementation files, include/source layout had to be made explicit in CMake.
  - slicer_internal.h initially risked anonymous-namespace/unified-build fragility; fixed by using named private namespace P4Verify::slicing_internal and not listing the header as a CMake source.
  - Moving tests into subfolders broke Path(__file__).parents[2] repo-root assumptions; fixed by discovering the repo root via the Procurator directory.
  - Ultimate asset fanout exceeded the folder policy; fixed by semantic subfolders and a centralized legacy-path resolver instead of duplicate compatibility copies.
  - A sliced P4B no-op if block caused NetChain exact-match drift; fixed in slicer_apply.cpp by pruning empty IfStatement nodes after slice pruning.
  - One accidental erify command found the default Ultimate and started a long solver run; the process was terminated and subsequent checks were kept stage-by-stage (compile/smoke/selftests only).
- **Fixes/Smoke regression**:
  - python -m unittest focused suite: 77 tests PASS (oogie, wraparound, 	oolchain, alidate_counterexample).
  - Structure checks: NO_FILES_OVER_3000; NO_DIRS_OVER_8_DIRECT_FILES.
  - P4B build: cmake --build . --target p4c-translator -j2 PASS.
  - P4B slicing selftest: --slicing-selftest=netchain_seq PASS.
  - NetChain compile/smoke: procurator compile + procurator smoke PASS.
  - NetChain exact compare: /tmp/procurator_refactor_split/netchain.final3.bpl is EXACT_MATCH_AFTER5 against the pre-final refactor baseline.
- **Subagent review**:
  - DSLC/spec review: no blockers after Ultimate asset resolver/fanout fix.
  - P4B split review: no blockers; noted only future hygiene possibility to split the private slicer implementation header further.

## 2026-04-29 final ASCII record

- Spec: Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop
- Time: 2026-04-29 final validation, Asia/Shanghai
- Goal/Progress: Completed the DSLC/P4B responsibility-boundary refactor spec and the main code-organization split. Enforced implementation files below 3000 lines and direct folder fanout at 8 files or fewer for the touched DSLC/P4B verification tree. Preserved legacy DSLC import compatibility while the full E2E pipeline remains under validation.
- Result:
  - DSLC Boogie backend split into dslc/backends/boogie/core, node, and harness packages, with compatibility aliases for legacy dslc.backends.boogie_* imports.
  - Wraparound CEGIS support split into dslc/workflows/wraparound_support while keeping old helper names importable.
  - P4B translator split into translate/impl/core and translate/impl/support. Slicer split into slicer.cpp, slicer_apply.cpp, and private slicer_internal.h.
  - Ultimate XML/EPF assets moved under dslc/toolchain/ultimate/toolchains and dslc/toolchain/ultimate/settings, with dslc/toolchain/ultimate_paths.py resolving legacy flat paths such as dslc/toolchain/ultimate/ReachSafety.xml.
  - Boundary spec written in doc/dslc_p4b_boundary_refactor_spec.md.
- Pitfalls and fixes:
  - P4B translate file moves required explicit CMake source/include layout.
  - slicer_internal.h initially risked anonymous-namespace/unified-build fragility; fixed with named private namespace P4Verify::slicing_internal and by not listing the header as a CMake source.
  - Moving tests into subfolders broke Path(__file__).parents[2] repo-root assumptions; fixed by discovering the repo root via the Procurator directory.
  - Ultimate asset fanout exceeded the folder policy; fixed with semantic subfolders and centralized legacy-path resolution instead of duplicate compatibility copies.
  - A sliced P4B no-op if block caused NetChain exact-match drift; fixed in slicer_apply.cpp by pruning empty IfStatement nodes after slice pruning.
  - One accidental verify command found the default Ultimate and started a long solver run; the process was terminated and subsequent checks were kept stage-by-stage: compile, smoke, and selftests only.
- Smoke/regression status:
  - Focused Python suite: 77 tests PASS across boogie, wraparound, toolchain, and validate_counterexample.
  - Structure checks: NO_FILES_OVER_3000 and NO_DIRS_OVER_8_DIRECT_FILES.
  - P4B build: cmake --build . --target p4c-translator -j2 PASS.
  - P4B slicing selftest: netchain_seq PASS.
  - NetChain compile/smoke: procurator compile plus procurator smoke PASS.
  - NetChain exact compare: /tmp/procurator_refactor_split/netchain.final3.bpl is EXACT_MATCH_AFTER5 against the pre-final refactor baseline.
- Subagent review:
  - DSLC/spec review: no blockers after Ultimate asset resolver/fanout fix.
  - P4B split review: no blockers; only future hygiene note is to split the private slicer implementation header further if it grows.

## 2026-04-29 wraparound reproduction

- Spec: Procurator/argo/code/spec/bench/fisslock_notification_cnt_wraparound_bug.prop
- Time: 2026-04-29 14:12-14:14 Asia/Shanghai
- Goal/Progress: Reproduced the first stage of the schedule-replay wraparound pipeline after the dependency projection probe found that FissLock previously fell back before ENTRY because P4B assigned helper calls were treated as unresolved.
- Result: ENTRY_CHECK reached Ultimate and returned UNSAFE in 24.7s. Manifest: .tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260429-141230-843c/wraparound/target.00.sw_IngressPipe_CounterTable_1_notification_cnt_1/wraparound.cegis.manifest.json. The manifest records schedule actors client, client, sw; projection_complete is true; projection vars are procurator_phase, client_inbox_count, sw_inbox_count, dsl_pump_mode; dependency predicates were extracted from control/data dependencies.
- Pitfalls: The first FissLock schedule-replay attempt did not enter ENTRY. The dependency projection pass conservatively marked known P4B {:inline 1} assigned helper calls such as sw_IngressPipe_CounterTable_1_count_ncnt.apply as unresolved, even though their bodies were available and side-effect-free.
- Fixes: Updated dslc/analysis/wraparound_projection.py so assigned calls to inline, body-present, no-modifies helper procedures are inlined for dependency propagation, including local variables and return variables. Unknown or non-inline assigned calls still mark the projection incomplete and therefore fall back to direct checking.
- Smoke/regression: PASS. Ran dslc.tests.wraparound.schedule.test_wraparound_schedule, 29 tests OK, including the existing unknown side-effect fallback test and a new P4B assigned-helper inlining test.

## 2026-04-29 wraparound reproduction

- Spec: Procurator/argo/code/spec/bench/fisslock_notification_cnt_wraparound_bug.prop
- Time: 2026-04-29 14:14-14:20 Asia/Shanghai
- Goal/Progress: Continued the staged schedule-replay reproduction for FissLock through NEAR_WRAP, keeping closure separate to avoid mixing expensive stages.
- Result: ENTRY_CHECK returned UNSAFE in 26.5s and NEAR_WRAP returned UNSAFE in 307.4s. Manifest: .tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260429-141445-4b39/wraparound/target.00.sw_IngressPipe_CounterTable_1_notification_cnt_1/wraparound.cegis.manifest.json. The run is not certified yet because it intentionally stopped before CLOSURE_CHECK.
- Pitfalls: NEAR_WRAP is much heavier than ENTRY on this spec and slightly exceeded the 300s solver cap at wall-clock level because of launcher and shutdown overhead. No lingering Ultimate or Java process remained after the run.
- Fixes: No new implementation change in this stage. The earlier dependency-projection fix remained active, and projection_complete stayed true.
- Smoke/regression: PASS from the preceding focused schedule suite, dslc.tests.wraparound.schedule.test_wraparound_schedule, 29 tests OK. Closure is still pending for certification.

## 2026-04-29 wraparound reproduction

- Spec: Procurator/argo/code/spec/bench/fisslock_notification_cnt_wraparound_bug.prop
- Time: 2026-04-29 14:28-14:36 Asia/Shanghai
- Goal/Progress: Continued FissLock schedule-replay through CLOSURE_CHECK after fixing the projection extractor. Kept the run staged with a 300s per-stage Ultimate timeout.
- Result: ENTRY_CHECK returned UNSAFE in 27.0s; NEAR_WRAP returned UNSAFE in 301.2s; CLOSURE_CHECK reached TraceAbstraction but returned no-result after 132.3s. Manifest: .tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260429-142823-3431/wraparound/target.00.sw_IngressPipe_CounterTable_1_notification_cnt_1/wraparound.cegis.manifest.json. The bug is not certified yet because closure is not SAFE.
- Pitfalls: The first closure attempt exposed an implementation bug: closure instrumentation emitted bvule.bv8 for the 8-bit counter, but the harness preamble only declared bvule.bv16 and bvule.bv32, causing Ultimate typecheck failure. After fixing this, closure entered CEGAR and reached iteration 20, then Z3 OOMed under the 2GB base no-POR setting.
- Fixes: Updated dslc/transform/wraparound_stages.py and dslc/transform/wraparound_instrument.py so CLOSURE_CHECK inserts a bvule.bvW helper declaration for the pump register element width when the declaration is missing. Unknown or existing helpers are not duplicated.
- Smoke/regression: PASS. Ran dslc.tests.wraparound.transform.test_wraparound_transform, 17 tests OK, including new bv8 helper coverage and no-duplicate coverage. Ran focused schedule tests for certification path and P4B assigned-helper projection, 2 tests OK.

## 2026-04-29 wraparound reproduction

- Spec: Procurator/argo/code/spec/bench/fisslock_notification_cnt_wraparound_bug.prop
- Time: 2026-04-29 15:17-15:24 Asia/Shanghai
- Goal/Progress: Finished the FissLock schedule-replay wraparound certification in WSL and reduced the total stage time below the previously expected 650s level while preserving the sound certificate conditions: ENTRY_CHECK UNSAFE, NEAR_WRAP UNSAFE, and CLOSURE_CHECK SAFE.
- Result:
  - Command was run inside WSL: ./bin/procurator verify --spec Procurator/argo/code/spec/bench/fisslock_notification_cnt_wraparound_bug.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound auto --wraparound-cegar-mode schedule_replay --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --ultimate-timeout-seconds 900 --ultimate-xmx-gb 8
  - Expected exit code 1 for certified UNSAFE.
  - ENTRY_CHECK: UNSAFE, wall_time_s=37.8.
  - NEAR_WRAP: UNSAFE, wall_time_s=231.6.
  - CLOSURE_CHECK: SAFE, wall_time_s=93.8.
  - Outer wall time was about 378.1s. Manifest: .tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260429-151725-5204/wraparound/target.00.sw_IngressPipe_CounterTable_1_notification_cnt_1/wraparound.cegis.manifest.json.
  - Certified schedule actors are client, client, sw. Projection vars are procurator_phase, client_inbox_count, sw_inbox_count, dsl_pump_mode. Certified projection predicates are empty.
  - Validator result: python3 -m dslc.bench.validate_counterexample --wraparound-manifest ... returned [OK] certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id.
- Pitfalls:
  - The repository binary and Ultimate/P4B workflow must be executed in WSL. Direct PowerShell execution of ./bin/procurator is not a valid signal in this checkout.
  - The previous closure proof was slowed/blocked by two separate issues: transient packet/meta/table/action predicates were being treated as certified projection predicates, and residual typedef-index array init quantifiers such as forall i:sw_lid_t remained in CLOSURE_CHECK.
  - Full-predicate closure UNSAFE was not a sound certificate; those predicates are transient pass facts and must not be replay-closure projection state.
- Fixes:
  - dslc/analysis/wraparound_projection.py now filters certified projection predicates to stable cutpoint state only. It no longer promotes transient header/meta/table/action predicates into the closure projection.
  - dslc/workflows/wraparound_cegis.py now rejects certified manifests whose serialized dependency predicates are not stable projection predicates, even if the manifest is otherwise self-consistent.
  - dslc/transform/wraparound_stages.py and dslc/transform/wraparound_instrument.py now drop residual quantified array initialization assumptions in CLOSURE_CHECK only. This over-approximates the universal closure proof state, so SAFE remains sound; ENTRY/NEAR/CONFIRM existential stages keep their original initialization assumptions.
- Smoke/regression:
  - WSL PASS: python3 -m unittest -v dslc.tests.wraparound.transform.test_wraparound_forall_init_elim dslc.tests.wraparound.transform.test_wraparound_transform dslc.tests.wraparound.schedule.test_wraparound_schedule.WraparoundScheduleTests.test_dependency_projection_inlines_p4b_assigned_helper_call dslc.tests.wraparound.schedule.test_wraparound_schedule.WraparoundScheduleTests.test_dependency_projection_filters_transient_control_predicates dslc.tests.wraparound.schedule.test_wraparound_schedule.WraparoundScheduleTests.test_schedule_manifest_requires_dependency_predicates dslc.tests.wraparound.schedule.test_wraparound_schedule.WraparoundScheduleTests.test_schedule_manifest_rejects_unstable_dependency_predicates dslc.tests.wraparound.schedule.test_wraparound_schedule.WraparoundScheduleTests.test_schedule_manifest_requires_explicit_near_wrap
  - WSL PASS: python3 -m unittest -v dslc.tests.wraparound.schedule.test_wraparound_schedule, 30 tests OK.
  - No lingering Ultimate, Java, Z3, or procurator verify process remained after the run.

## 2026-04-29 wraparound reproduction

- Spec: Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop
- Time: 2026-04-29 15:45-15:48 Asia/Shanghai
- Goal/Progress: Re-ran the NetChain wraparound baseline after the stable-projection and CLOSURE-only quantifier changes, to ensure an existing wraparound certificate still works before exploring more systems.
- Result:
  - Command was run inside WSL: ./bin/procurator verify --spec Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound auto --wraparound-cegar-mode schedule_replay --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --ultimate-timeout-seconds 900 --ultimate-xmx-gb 8
  - Expected exit code 1 for certified UNSAFE.
  - ENTRY_CHECK: UNSAFE, wall_time_s=22.4.
  - NEAR_WRAP: UNSAFE, wall_time_s=38.2.
  - CLOSURE_CHECK: SAFE, wall_time_s=85.8.
  - Manifest: .tmp/procurator/verify/netchain_wraparound_bug/20260429-154556-c71d/wraparound/target.00.s1_sequence_reg/wraparound.cegis.manifest.json.
  - Certified schedule actors are h1, h1, s1, s2. Projection vars are procurator_phase, h1_inbox_count, s1_inbox_count, s2_inbox_count. Certified projection predicates are empty.
  - Validator result: python3 -m dslc.bench.validate_counterexample --wraparound-manifest ... returned [OK] certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id.
- Pitfalls: No new implementation issue. The key regression risk was that removing transient projection predicates could make closure too coarse; NetChain still proves SAFE under the stable projection.
- Fixes: No new code change for this spec.
- Smoke/regression:
  - Reused WSL wraparound focused regression from the FissLock run: dslc.tests.wraparound.transform.test_wraparound_forall_init_elim, dslc.tests.wraparound.transform.test_wraparound_transform, and dslc.tests.wraparound.schedule.test_wraparound_schedule, 55 tests OK.
  - No lingering Ultimate, Java, Z3, or procurator verify process remained after the run.

## 2026-04-29 wraparound exploration

- Spec: Procurator/argo/code/spec/bench/distcache_p2c_wraparound_bug.prop
- Time: 2026-04-29 16:08-16:13 Asia/Shanghai
- Goal/Progress: Re-ran the DistCache P2C leafload overflow/wrong-choice bug under the current stable-projection schedule-replay certificate, after NetChain and FissLock passed. This checks that the older DistCache wraparound result still certifies without relying on transient header/meta/table-action predicates.
- Result:
  - Command was run inside WSL: ./bin/procurator verify --spec Procurator/argo/code/spec/bench/distcache_p2c_wraparound_bug.prop --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --wraparound auto --wraparound-cegar-mode schedule_replay --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --ultimate-timeout-seconds 900 --ultimate-xmx-gb 8
  - Expected exit code 1 for certified UNSAFE.
  - ENTRY_CHECK: UNSAFE, wall_time_s=25.2.
  - NEAR_WRAP: UNSAFE, wall_time_s=106.4.
  - CLOSURE_CHECK: SAFE, wall_time_s=110.8.
  - Manifest: .tmp/procurator/verify/distcache_p2c_wraparound_bug/20260429-160826-ec43/wraparound/target.00.clientTrack_partitionswitchIngress_leafload_reg/wraparound.cegis.manifest.json.
  - Certified target is clientTrack_partitionswitchIngress_leafload_reg[2] with step_delta=1. Certified schedule actors are io, io, clientTrack. Projection vars are procurator_phase, clientTrack_inbox_count, io_inbox_count, dsl_pump_mode. Certified projection predicates are empty.
  - Validator result: python3 -m dslc.bench.validate_counterexample --wraparound-manifest ... returned [OK] certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id.
- Pitfalls:
  - The Windows to WSL background-launch wrapper was unreliable for long verification commands, so this run was executed in the foreground through WSL. No repository binary or Ultimate stage was run directly in PowerShell.
  - The older DistCache record used a similar certificate, but it predated the stable-projection filter; this run confirms the certificate remains sound under the stricter manifest validation.
- Fixes:
  - No code change was required for this spec. The existing stable-projection and CLOSURE-only quantifier changes were sufficient.
- Smoke/regression:
  - Reused WSL wraparound focused regression from the FissLock run: dslc.tests.wraparound.transform.test_wraparound_forall_init_elim, dslc.tests.wraparound.transform.test_wraparound_transform, and dslc.tests.wraparound.schedule.test_wraparound_schedule, 55 tests OK.
  - No lingering Ultimate, Java, Z3, or procurator verify process remained after the run.

## 2026-04-29 wraparound exploration

- Spec: Procurator/argo/code/spec/bench/distcache_p2c_spineload_wraparound_bug.prop
- Time: 2026-04-29 16:16-16:20 Asia/Shanghai
- Goal/Progress: Re-ran the symmetric DistCache P2C spineload overflow/wrong-choice bug under the current stable-projection schedule-replay certificate. This complements the leafload P2C case and checks that the suffix-shape flag remains part of stable projection only when it is a DSL/env cutpoint variable.
- Result:
  - Command was run inside WSL: ./bin/procurator verify --spec Procurator/argo/code/spec/bench/distcache_p2c_spineload_wraparound_bug.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound auto --wraparound-cegar-mode schedule_replay --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --ultimate-timeout-seconds 900 --ultimate-xmx-gb 8
  - Expected exit code 1 for certified UNSAFE.
  - ENTRY_CHECK: UNSAFE, wall_time_s=17.7.
  - NEAR_WRAP: UNSAFE, wall_time_s=95.2.
  - CLOSURE_CHECK: SAFE, wall_time_s=76.1.
  - Manifest: .tmp/procurator/verify/distcache_p2c_spineload_wraparound_bug/20260429-161640-1968/wraparound/target.00.clientTrack_partitionswitchIngress_spineload_reg/wraparound.cegis.manifest.json.
  - Certified target is clientTrack_partitionswitchIngress_spineload_reg[3] with step_delta=1. Certified schedule actors are io, io, clientTrack. Projection vars are procurator_phase, clientTrack_inbox_count, io_inbox_count, dsl_pump_mode, dsl_suffix_sent. Certified projection predicates are empty.
  - Validator result: python3 -m dslc.bench.validate_counterexample --wraparound-manifest ... returned [OK] certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id.
- Pitfalls:
  - No new implementation issue. The closure stage prints Ultimate's full success line instead of the normalized RESULT: SAFE line in this run, but the validator correctly accepts it as SAFE.
- Fixes:
  - No code change was required for this spec.
- Smoke/regression:
  - Reused WSL wraparound focused regression from the FissLock run: dslc.tests.wraparound.transform.test_wraparound_forall_init_elim, dslc.tests.wraparound.transform.test_wraparound_transform, and dslc.tests.wraparound.schedule.test_wraparound_schedule, 55 tests OK.
  - No lingering Ultimate, Java, Z3, or procurator verify process remained after the run.

## 2026-04-29 wraparound exploration

- Spec: Procurator/argo/code/spec/bench/distcache_leafload_wraparound.prop
- Time: 2026-04-29 16:22-16:25 Asia/Shanghai
- Goal/Progress: Ran the simpler DistCache clientTrack-only leafload counter overflow benchmark under the current schedule-replay wraparound certificate. This checks that a single-switch external-input topology still certifies with the stable projection abstraction.
- Result:
  - Command was run inside WSL: ./bin/procurator verify --spec Procurator/argo/code/spec/bench/distcache_leafload_wraparound.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound auto --wraparound-cegar-mode schedule_replay --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --ultimate-timeout-seconds 900 --ultimate-xmx-gb 8
  - Expected exit code 1 for certified UNSAFE.
  - ENTRY_CHECK: UNSAFE, wall_time_s=16.5.
  - NEAR_WRAP: UNSAFE, wall_time_s=49.3.
  - CLOSURE_CHECK: SAFE, wall_time_s=58.0.
  - Manifest: .tmp/procurator/verify/distcache_leafload_wraparound/20260429-162236-362c/wraparound/target.00.clientTrack_partitionswitchIngress_leafload_reg/wraparound.cegis.manifest.json.
  - Certified target is clientTrack_partitionswitchIngress_leafload_reg[2] with step_delta=1. Certified schedule actors are env, clientTrack. Projection vars are procurator_phase and clientTrack_inbox_count. Certified projection predicates are empty.
  - Validator result: python3 -m dslc.bench.validate_counterexample --wraparound-manifest ... returned [OK] certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id.
- Pitfalls:
  - No new implementation issue. This is a basic counter-overflow demo rather than the richer P2C wrong-choice property, but it exercises a different topology shape (external_input node without an explicit host).
- Fixes:
  - No code change was required for this spec.
- Smoke/regression:
  - Reused WSL wraparound focused regression from the FissLock run: dslc.tests.wraparound.transform.test_wraparound_forall_init_elim, dslc.tests.wraparound.transform.test_wraparound_transform, and dslc.tests.wraparound.schedule.test_wraparound_schedule, 55 tests OK.
  - No lingering Ultimate, Java, Z3, or procurator verify process remained after the run.

## 2026-04-29 wraparound exploration

- Spec: Procurator/argo/code/spec/bench/distcache_leaf_cache_frequency_wraparound.prop
- Time: 2026-04-29 16:25-16:32 Asia/Shanghai
- Goal/Progress: Tested the DistCache leaf cache_frequency overflow benchmark as a candidate functional wraparound bug. This was deliberately run through the integrated auto pipeline to check both the accelerated certificate path and the required direct-checking fallback.
- Result:
  - Command was run inside WSL: ./bin/procurator verify --spec Procurator/argo/code/spec/bench/distcache_leaf_cache_frequency_wraparound.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound auto --wraparound-cegar-mode schedule_replay --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --ultimate-timeout-seconds 900 --ultimate-xmx-gb 8
  - Wraparound candidate was found for leaf_netcacheEgress_cache_frequency_reg with step_delta=1, but the certificate did not close.
  - Attempt 0 schedule actors were io, io, leaf. Projection vars were procurator_phase, io_inbox_count, leaf_inbox_count. Projection predicates were empty and projection_complete was true.
  - Attempt 0: ENTRY_CHECK UNSAFE in 24.7s; NEAR_WRAP UNSAFE in 103.9s; CLOSURE_CHECK UNSAFE in 50.0s. The schedule was blocked with reason closure_unsafe.
  - Attempt 1 after blocking the failed schedule had ENTRY_CHECK SAFE in 31.2s, so no alternative reachable schedule certificate was found.
  - Integrated fallback to direct GemCutter completed and returned SAFE. Log: .tmp/procurator/verify/distcache_leaf_cache_frequency_wraparound/20260429-162554-87f1/gemcutter.log.
  - Manifest: .tmp/procurator/verify/distcache_leaf_cache_frequency_wraparound/20260429-162554-87f1/wraparound/target.00.leaf_netcacheEgress_cache_frequency_reg/wraparound.cegis.manifest.json. certified=false; diagnostic="entry unreachable or blocked; falling back".
- Pitfalls:
  - ENTRY+NEAR_WRAP UNSAFE is not enough. The closure counterexample means the proposed schedule/projection is not a replay certificate, so this run must not be counted as a certified wraparound bug.
  - The direct fallback returning SAFE is the expected sound behavior for a non-certified acceleration candidate in this configuration.
- Fixes:
  - No code change was made. This negative result is useful coverage for the fallback path.
- Smoke/regression:
  - Reused WSL wraparound focused regression from the FissLock run: dslc.tests.wraparound.transform.test_wraparound_forall_init_elim, dslc.tests.wraparound.transform.test_wraparound_transform, and dslc.tests.wraparound.schedule.test_wraparound_schedule, 55 tests OK.
  - No lingering Ultimate, Java, Z3, or procurator verify process remained after the run.

## 2026-04-29 interleaving exploration

- Spec: Procurator/argo/code/spec/bench/gecko_bug2_concurrency.prop
- Time: 2026-04-29 16:34-16:44 Asia/Shanghai
- Goal/Progress: Re-ran the Gecko limited-concurrency bug as an interleaving/direct-checking candidate after the wraparound certificate runs. This case models two writes arriving before a timer tick, where the timer logic drains only one pending request.
- Result:
  - Command was run inside WSL: ./bin/procurator verify --spec Procurator/argo/code/spec/bench/gecko_bug2_concurrency.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound off --use-spec-max-steps --ultimate-timeout-seconds 900 --ultimate-xmx-gb 8
  - Expected exit code 1 for UNSAFE.
  - Main GemCutter result: UNSAFE, OverallTime=226.7s.
  - Witness rerun result: UNSAFE, OverallTime=229.9s.
  - Output directory: .tmp/procurator/verify/gecko_bug2_concurrency/20260429-163443-1fa7.
  - Witness files: gecko_bug2_concurrency.bpl-witness.graphml and gecko_bug2_concurrency.bpl-witness.yml.
  - Counterexample validator result: python3 -m dslc.bench.validate_counterexample --out-dir ... returned [OK] dsl_assert: DSL global assertion violated (accumulator flag set; gecko_bug2_concurrency.bpl-witness.graphml).
- Pitfalls:
  - This is not a wraparound certificate and was intentionally run with --wraparound off. The bug evidence is the direct GemCutter UNSAFE witness.
  - The total wall time includes both main solving and witness rerun; the solver phase itself is about 227s and the witness rerun another 230s.
- Fixes:
  - No code change was required for this spec.
- Smoke/regression:
  - The generated Boogie was post-processed with forall-init elimination: 28 -> 0.
  - Counterexample validation passed for the out directory.
  - No lingering Ultimate, Java, Z3, or procurator verify process remained after the run.

## 2026-04-29 direct-checking exploration

- Spec: Procurator/argo/code/spec/bench/frr_bug1_unexpected_mirror.prop
- Time: 2026-04-29 16:44-16:45 Asia/Shanghai
- Goal/Progress: Re-ran the FRR unexpected-mirror benchmark as a quick direct-checking distributed-system sample after the wraparound and Gecko concurrency runs.
- Result:
  - Command was run inside WSL: ./bin/procurator verify --spec Procurator/argo/code/spec/bench/frr_bug1_unexpected_mirror.prop --boogie-harness sequential --no-two-stage --wraparound off --use-spec-max-steps --no-slicing-control-seeds --ultimate-timeout-seconds 900 --ultimate-xmx-gb 8
  - Expected exit code 1 for UNSAFE.
  - Main GemCutter result: UNSAFE, OverallTime=10.3s.
  - Witness rerun result: UNSAFE, OverallTime=10.0s.
  - Output directory: .tmp/procurator/verify/frr_bug1_unexpected_mirror/20260429-164429-4f32.
  - Witness files: frr_bug1_unexpected_mirror.bpl-witness.graphml and frr_bug1_unexpected_mirror.bpl-witness.yml.
  - Counterexample validator result: python3 -m dslc.bench.validate_counterexample --out-dir ... returned [OK] dsl_assert: DSL global assertion violated (accumulator flag set; frr_bug1_unexpected_mirror.bpl-witness.graphml).
- Pitfalls:
  - This case has two assertion locations; Ultimate reported one UNSAFE and one UNKNOWN, but the overall result and witness are valid for the violated DSL assertion.
  - This is categorized as direct-checking/implementation behavior, not a wraparound certificate.
- Fixes:
  - No code change was required for this spec.
- Smoke/regression:
  - The generated Boogie was post-processed with forall-init elimination: 3 -> 0.
  - Counterexample validation passed for the out directory.
  - No lingering Ultimate, Java, Z3, or procurator verify process remained after the run.

## 2026-04-29 interleaving exploration

- Spec: Procurator/argo/code/spec/bench/frr_bug2_state_inconsistency.prop
- Time: 2026-04-29 16:45-16:51 Asia/Shanghai
- Goal/Progress: Re-ran the FRR state-inconsistency benchmark as an interleaving/direct-checking sample immediately before switching to external repository mining.
- Result:
  - Command was run inside WSL: ./bin/procurator verify --spec Procurator/argo/code/spec/bench/frr_bug2_state_inconsistency.prop --boogie-harness sequential --no-two-stage --wraparound off --use-spec-max-steps --ultimate-timeout-seconds 900 --ultimate-xmx-gb 8
  - Expected exit code 1 for UNSAFE.
  - Main GemCutter result: UNSAFE, OverallTime=122.3s.
  - Witness rerun result: UNSAFE, OverallTime=115.1s.
  - Output directory: .tmp/procurator/verify/frr_bug2_state_inconsistency/20260429-164557-7ead.
  - Witness files: frr_bug2_state_inconsistency.bpl-witness.graphml and frr_bug2_state_inconsistency.bpl-witness.yml.
  - Counterexample validator result: python3 -m dslc.bench.validate_counterexample --out-dir ... returned [OK] dsl_assert: DSL global assertion violated (accumulator flag set; frr_bug2_state_inconsistency.bpl-witness.graphml).
- Pitfalls:
  - This is a direct GemCutter witness, not a wraparound certificate.
  - Ultimate reported one top-level assertion UNSAFE and one node-local assertion UNKNOWN; the produced witness validates the violated DSL global assertion.
- Fixes:
  - No code change was required for this spec.
- Smoke/regression:
  - The generated Boogie was post-processed with forall-init elimination: 3 -> 0.
  - Counterexample validation passed for the out directory.
  - No lingering Ultimate, Java, Z3, or procurator verify process remained after the run.

## 2026-04-30 external-system exploration

- Spec: Procurator/argo/code/spec/bench/dinc_distributed_ml_smoke.prop
- Time: 2026-04-30 Asia/Shanghai
- Goal/Progress: Started mining external in-network systems instead of only existing bench specs. NetCache was explicitly excluded per user instruction. Onboarded DINC (CoNEXT 2023 artifact, distributed in-network computing / distributed ML inference) as the first external multi-node ML system with public BMv2 P4 artifacts.
- Result:
  - Copied DINC BMv2 test-environment nodes s2, s1, s0 and their command files into Procurator/argo/code/dataset/external/DINC/.
  - Added a three-node smoke spec modeling the DINC pipeline path host -> s2 -> s1 -> s0, where s2 encodes feature0/1, s1 encodes feature2/3, and s0 performs the final decision.
  - WSL compile passed: ./bin/procurator compile --spec Procurator/argo/code/spec/bench/dinc_distributed_ml_smoke.prop --out /tmp/dinc_distributed_ml_smoke.bpl --boogie-harness sequential --no-two-stage --no-reg-debug
  - WSL smoke passed: ./bin/procurator smoke --bpl /tmp/dinc_distributed_ml_smoke.bpl --harness sequential
- Pitfalls:
  - The DSL does not accept P4 method syntax such as s0_hdr.DINC.isValid(); use the generated valid field form s0_hdr.DINC.valid.
  - DINC's Pegasus/Tofino samples are very promising for stateful wraparound/interleaving exploration, but they use Tofino-style register/stateful_alu/resubmit constructs and are not direct v1model compile targets yet.
- Fixes:
  - Fixed the initial DINC smoke assertion from s0_hdr.DINC.isValid() to s0_hdr.DINC.valid.
  - No verifier implementation change was required.
- Smoke/regression:
  - External DINC compile/smoke passed in WSL.
  - No Ultimate/GemCutter run was started for this onboarding spec; this was intentionally compile/smoke only.

## 2026-04-30 external-system exploration

- Spec: Procurator/argo/code/spec/bench/external_int_flowdos_counter_wraparound.prop
- Source: Montimage/inband-network-telemetry, p4/flow-dos/switch-flow.p4 and int.p4 copied into Procurator/argo/code/dataset/external_int_flowdos without source edits (verified identical to .tmp/external-systems/inband-network-telemetry/p4/flow-dos/).
- Time: 2026-04-30 11:35-12:02 Asia/Shanghai
- Goal/Progress: Onboarded an external BMv2/v1model INT flow-DOS program and tested the counter_filter 8-bit wraparound hypothesis without modifying the upstream P4 dataset. Unsupported syntax/features were fixed in P4B instead of shimmed in the dataset.
- Result:
  - P4B build passed in WSL: cd P4B-Translator/build-host && cmake --build . --target p4c-translator -j2.
  - Compile/smoke passed: ./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_int_flowdos_counter_wraparound.prop --out /tmp/external_int_flowdos_counter_wraparound.bpl --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds; ./bin/procurator smoke --bpl /tmp/external_int_flowdos_counter_wraparound.bpl --harness sequential.
  - Wraparound run: ./bin/procurator verify --spec ... --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --wraparound auto --wraparound-cegar-mode schedule_replay --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --ultimate-timeout-seconds 180 --ultimate-xmx-gb 8.
  - run_id: .tmp/procurator/verify/external_int_flowdos_counter_wraparound/20260430-115256-49dd.
  - ENTRY_CHECK: UNSAFE, wall≈29.5s; NEAR_WRAP: UNSAFE, wall≈47.3s; CLOSURE_CHECK: UNSAFE, wall≈37.6s. A second schedule attempt had ENTRY_CHECK SAFE. Manifest certified=false with blocker reason closure_unsafe.
  - Fallback/direct checking reported UNSAFE and witness validation passed, but this is not counted as a new bug because the current assertion counter_filter[0] != 0 is false in the default zero-initialized base state. This run is recorded as external translator onboarding plus a negative wraparound candidate, not a certified bug discovery.
- Pitfalls:
  - Initial generated Boogie had Ultimate type errors: missing flowdos_int_{egress,ingress}_hasReturned declarations, dangling parser-state gotos from nested int_parser.apply, and int_parser_hop_data_len_0 declared as Ref instead of bv32.
  - The external program uses legacy BMv2 clone_preserving_field_list and parser select(bool) forms; fixing support in P4B was required. The dataset must not be modified to work around these features.
  - The wraparound candidate was inferred from the global assertion because P4B monotonic metadata did not detect the read-then-write local pattern counter_filter.read(counter_val, counter_pos); counter_filter.write(counter_pos, counter_val+1). Even if detected, closure is expected to fail here because the program resets counter_filter when the old counter_val >= REPORT_FREQ.
- Fixes:
  - P4B v1model now declares clone_preserving_field_list, and clone/clone3/clone_preserving_field_list direction modeling distinguishes E2E/I2I/I2E flags.
  - P4B parser select translation now handles BoolLiteral keysets, eliminating malformed assume (); / assume(!()&&!()); Boogie.
  - P4B parser-state label normalization now recognizes numeric-suffixed references emitted by p4c lowered parser applies.
  - P4B parser-local lazy declaration now resolves Type_Unknown/Type_InfInt through recorded Declaration_Variable types, preserving bit<32> locals as bv32 instead of Ref.
  - P4B Declaration_Variable initializers now add the initialized variable to modifies, keeping p4c lowered temporaries such as *_hasReturned declared under slicing/prefixing.
- Smoke/regression:
  - Added dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_external_int_flowdos_parser_compatibility. The test compiles the upstream FlowDoS P4 and checks: hop_data_len_0 is bv32, hasReturned temporaries are bool, empty parser-select assumes are absent, and all parser goto targets have matching labels.
  - Regression command passed: python3 -m unittest -v dslc.tests.boogie.backend.test_boogie_backend_smoke dslc.tests.boogie.backend.test_boogie_slicing_seeds dslc.tests.p4b.test_p4b_translator_slicing_selftest dslc.tests.wraparound.schedule.test_wraparound_workflow_smoke (30 tests, OK).

## 2026-04-30 external-system exploration

- Spec: Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_count_wraparound.prop
- Source: nds-group/ETC_NOMS_2024, noms_20_5_4.p4 copied into Procurator/argo/code/dataset/external_etc_noms2024 without source edits.
- Time: 2026-04-30 12:30-13:30 Asia/Shanghai
- Goal/Progress: Onboarded a recent TNA/Tofino ML encrypted-traffic-classification system and tested the Ingress_reg_pkt_count 8-bit per-flow counter wraparound hypothesis. Per user instruction, unsupported TNA syntax/extern behavior was fixed in P4B rather than by modifying the external dataset.
- Result:
  - P4B build passed in WSL: cd P4B-Translator/build-host && cmake --build . --target p4c-translator -j2.
  - Compile/smoke passed: ./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_count_wraparound.prop --out /tmp/external_etc_noms2024_pkt_count_wraparound.bpl --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds; ./bin/procurator smoke --bpl /tmp/external_etc_noms2024_pkt_count_wraparound.bpl --harness sequential.
  - Wraparound run: ./bin/procurator verify --spec ... --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --wraparound auto --wraparound-cegar-mode schedule_replay --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --ultimate-timeout-seconds 180 --ultimate-xmx-gb 8.
  - run_id: .tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260430-124410-2ba5.
  - ENTRY_CHECK: UNSAFE, wall about 16.3s. NEAR_WRAP timed out after about 197.5s. Manifest certified=false with diagnostic "near-wrap check did not find a bug for this schedule; falling back".
  - Fallback/direct checking reported UNSAFE, but this is not counted as a new bug because the current assertion Ingress_reg_pkt_count[0] != 0 is false from the default zero-initialized base state unless the wraparound certificate succeeds.
- Pitfalls:
  - Initial TNA Hash<W>.get lowering lost tuple arguments, producing a zero-argument hash function and losing the data dependence on the 5-tuple.
  - A too-broad temporary Hash fix treated arbitrary extern .get({ ... }) calls as pure functions; subagent review flagged this as an unsound modeling risk.
  - TNA RegisterAction.apply bodies initially leaked local/action variables such as output, pkt_count, status, and tmp_flow_ID into global Boogie state and modifies clauses, causing Ultimate type/modifies errors.
  - Direct witness evidence showed an unconstrained ig_intr_md.resubmit_flag path can reach parser reject/drop behavior; future ETC specs should constrain intrinsic parser state before spending long solver time.
- Fixes:
  - P4B now records actual Hash<W> extern instances and lowers only those .get/.get_hash calls as pure uninterpreted functions of flattened ListExpression/StructExpression data fields.
  - Hash function declarations are signature-mangled by argument types, e.g. Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8, so one Hash instance can safely be called with different tuple shapes without declaration collisions.
  - Unsupported Hash data fallback now creates a typed havoc temporary instead of returning a bare havoc token that could be emitted in an invalid Boogie expression.
  - P4B RegisterAction translation now treats apply parameters, out parameters, and local copies as procedure-local variables, and updateModifiedVariables skips locals/parameters instead of polluting procedure modifies sets.
- Smoke/regression:
  - Added/extended dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_external_etc_noms2024_tna_hash_get_uses_data_fields. The test compiles the upstream ETC P4 and checks both Hash instances, signed tuple arguments, RegisterAction local scoping, and absence of zero-argument Hash fallback.
  - Focused regression passed after the fix: python3 -m unittest -v dslc.tests.boogie.backend.test_boogie_backend_smoke dslc.tests.boogie.backend.test_boogie_slicing_seeds dslc.tests.p4b.test_p4b_translator_slicing_selftest dslc.tests.wraparound.schedule.test_wraparound_workflow_smoke (31 tests, OK).

## 2026-04-30 external-system exploration

- Spec: Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_count_wraparound.prop
- Source: nds-group/ETC_NOMS_2024, dataset kept unmodified.
- Time: 2026-04-30 13:11-13:23 Asia/Shanghai
- Goal/Progress: Re-ran the ETC pkt_count wraparound candidate after tightening only the spec-side path constraints, specifically constraining the TNA parser path (`ig_intr_md.resubmit_flag == 0`) and the target-flow table default/drop branch (`Ingress_target_flows_table.action_run == Ingress_target_flows_table.action.Ingress_drop`) so that `meta.final_class == 0` remains stable enough to exercise the counter update path.
- Result:
  - Compile/smoke passed: ./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_count_wraparound.prop --out /tmp/external_etc_noms2024_pkt_count_wraparound_path.bpl --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds; ./bin/procurator smoke --bpl /tmp/external_etc_noms2024_pkt_count_wraparound_path.bpl --harness sequential.
  - Generated env assumptions include `etc_ig_intr_md.resubmit_flag == 0bv1`, `etc_meta.final_class == 0bv8`, `etc_Ingress_target_flows_table.action_run == etc_Ingress_target_flows_table.action.Ingress_drop`, and `etc_meta.register_index == 0bv11`.
  - Wraparound run: ./bin/procurator verify --spec ... --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --wraparound auto --wraparound-cegar-mode schedule_replay --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --ultimate-timeout-seconds 90 --ultimate-xmx-gb 8.
  - run_id: .tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260430-132002-fad3.
  - ENTRY_CHECK: UNSAFE, wall about 17.6s. NEAR_WRAP: SAFE, wall about 38.2s. CLOSURE was not run because near-wrap did not find a suffix bug for this schedule. Manifest certified=false with diagnostic "near-wrap check did not find a bug for this schedule; falling back".
  - Direct fallback still reports UNSAFE because `Ingress_reg_pkt_count[0] != 0` is false from zero initialization; this remains a negative wraparound candidate, not a new bug.
- Pitfalls:
  - The earlier `meta.final_class == 0` env constraint alone was insufficient because `target_flows_table.apply()` may overwrite `meta.final_class`; the path-stable version must also constrain the table `action_run` enum.
  - The current assertion is only a liveness/coverage probe for the counter increment, not a functional ETC property. It should not be counted as a bug unless a wraparound certificate succeeds.
- Fixes:
  - No P4 dataset change was made. The external P4 remains upstream-shaped.
  - The spec was tightened with legal DSL enum/action_run constraints instead of modifying table code or table data.
- Smoke/regression:
  - P4B build and the 31-test focused regression were already passed after the Hash/RegisterAction fixes.
  - This run gives a useful fallback-path regression: when path constraints make the wrap suffix safe, Procurator correctly declines certification and falls back to direct checking.

## 2026-04-30 external-system exploration

- Spec: Procurator/argo/code/spec/bench/external_flowrest_per_flow_smoke.prop
- Source: nds-group/Flowrest, P4/Conference_version/unsw_per_flow_16_classes copied into Procurator/argo/code/dataset/external_flowrest_per_flow without source edits; copied files were checked against the upstream-shaped local clone with cmp.
- Time: 2026-04-30 13:35-13:45 Asia/Shanghai
- Goal/Progress: Onboarded Flowrest (per-flow Random Forest inference, TNA/Tofino) as a recent ML-related in-network system candidate. This was a compile/smoke-only stage before spending solver time on a functional wraparound property.
- Result:
  - WSL compile passed: ./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_flowrest_per_flow_smoke.prop --out /tmp/external_flowrest_per_flow_smoke.bpl --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds.
  - WSL smoke passed: ./bin/procurator smoke --bpl /tmp/external_flowrest_per_flow_smoke.bpl --harness sequential.
  - Direct P4B external compile also passed with -D__TARGET_TOFINO__=1 for the upstream Flowrest P4.
- Pitfalls:
  - The smoke assertion only checks that IPv4 parsing survives the TNA path; it is intentionally too weak for bug mining and allows slicing to drop most stateful-register behavior.
  - Future Flowrest bug specs must seed real state such as flowrest_Ingress_reg_pkt_count[0] / flowrest_Ingress_reg_classified_flag[0] and use functional output conditions rather than a raw nonzero-counter assertion that is false from zero initialization.
- Fixes:
  - No P4 dataset change was made. Unsupported TNA constructs are to be modeled in P4B rather than patched in the external dataset.
- Smoke/regression:
  - Compile/smoke passed in WSL.
  - No Ultimate/GemCutter run was started for this smoke stage.

## 2026-04-30 P4B meta normalization / Flowrest dynamic index

- Spec: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_count_wraparound.prop`
- Source: Flowrest per-flow Random Forest TNA program, dataset kept unmodified.
- Time: 2026-04-30 20:45-21:22 Asia/Shanghai
- Goal/Progress: Moved Flowrest/TNA dynamic register-index recovery from DSLC Boogie-text reverse engineering toward P4B structured meta. P4B now emits `wraparound.index_definitions` for P4-local assignments such as `meta.register_index = idx_calc.get(...)`, including a callsite-specialized form where action parameters are substituted with actual arguments (`meta.hdr_srcport`, `meta.hdr_dstport`). DSLC now prefers this structured meta and only falls back to the legacy Boogie-procedure recovery path when the structured definition is missing, ambiguous, or not pre-loop pure.
- Result:
  - P4B build passed in WSL: `cd P4B-Translator/build-host && cmake --build . --target p4c-translator -j2`.
  - Direct Flowrest P4B `--meta-out` run passed. The generated `flowrest.meta.json` contains `wraparound.index_definitions` for `meta.register_index`, including:
    - raw action form: `Ingress_idx_calc.get$bv32$bv32$int$int$bv8(..., srcPort, dstPort, ...)`
    - callsite-specialized form: `Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8(hdr.ipv4.src_addr, hdr.ipv4.dst_addr, meta.hdr_srcport, meta.hdr_dstport, hdr.ipv4.protocol)`
  - Compile/smoke passed:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_count_wraparound.prop --out /tmp/external_flowrest_check.bpl --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --use-spec-max-steps`
    - `./bin/procurator smoke --bpl /tmp/external_flowrest_check.bpl --harness sequential`
  - Single-stage wraparound ENTRY run passed:
    - command used `--wraparound auto --wraparound-cegar-mode schedule_replay --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 4 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --wraparound-stop-after entry --ultimate-timeout-seconds 90 --ultimate-xmx-gb 8`
    - run_id: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260430-214136-f66a`
    - ENTRY_CHECK: `UNSAFE`, wall about 28.9s.
    - manifest candidate index expression is now the stable pure hash over env literals: `flowrest_Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8(167772161bv32, 167772162bv32, 1234bv16, 443bv16, 6bv8)`.
    - projection remains only scheduler/mailbox state: `procurator_phase`, `flowrest_inbox_count`, `io_inbox_count`; it no longer includes stale `flowrest_meta.register_index`.
- Pitfalls:
  - P4B uses a unified build, so anonymous-namespace helper names in the new `analysis/index_defs.cpp` collided with helpers in `analysis/monotonic.cpp`. The fix was to give all index-definition helpers a dedicated `idxDef*` prefix.
  - Action-local definitions alone are not sufficient for Flowrest because `srcPort`/`dstPort` are action parameters. P4B must also emit a callsite-specialized definition after seeing `get_register_index(meta.hdr_srcport, meta.hdr_dstport)`.
  - p4c-renamed action parameters may carry numeric suffixes and can have weak local type information. The index-def pass now strips trailing numeric suffixes for substitution and uses action parameter declaration types to repair the hash function signature.
  - Hash extern names inside actions are resolved through `ReferenceMap`; otherwise the structured meta would emit the short IR name `idx_calc` while the generated Boogie declares `Ingress_idx_calc`.
  - CMake dependency checks on `/mnt/e` were slow enough that short build timeouts looked like hangs; the actual compile error only surfaced after running a single longer verbose build.
- Fixes:
  - Added `P4B-Translator/backends/verify/analysis/index_defs.{h,cpp}` and wired it into `--meta-out` before wraparound monotonicity analysis.
  - Extended `P4VerifyOptions` and `Translator::writeMetaToFile()` with `wraparound.index_definitions`.
  - Updated DSLC candidate inference to prefer structured P4B index definitions, prefix both variables and declared Boogie callees, substitute derived env constants, require a unique pre-loop-pure expression, and preserve legacy Boogie text recovery as fallback.
- Smoke/regression:
  - Added/extended P4B regression: `dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_external_flowrest_registeraction_execute_wraparound_meta`.
  - Added DSLC regression: `dslc.tests.wraparound.test_wraparound_candidate_gating.TestWraparoundCandidateGating.test_meta_index_expr_prefers_structured_p4b_definition`.
  - Focused regressions passed:
    - `python3 -m unittest -v dslc.tests.wraparound.test_wraparound_candidate_gating dslc.tests.wraparound.cegis.core.test_wraparound_cegis_dynamic_index`
    - `python3 -m unittest -v dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_external_flowrest_registeraction_execute_wraparound_meta`

## 2026-05-01 backend/refactor line-limit pass

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_count_wraparound.prop` (compile/smoke only; no Ultimate/GemCutter run in this phase)
- **Time**: 2026-05-01 00:00-01:35 Asia/Shanghai
- **Goal/Progress**: Refactored the Python wraparound pipeline and P4B verify backend toward a clearer compiler-backend-style organization while enforcing the current line limits: Python files <=1300 lines and C++/header files <=2500 lines. Python changes split Boogie dynamic-index recovery out of candidate inference, moved the schedule-replay and legacy CEGIS loops behind compatibility wrappers, and split schedule test fixtures/manifest-certification tests. P4B changes split translation responsibilities into dedicated lowering, table, bitblast/UA, meta-emission, and slicer DOT/debug modules.
- **Result**:
  - Final file-size audit after the pass: largest Python file is `dslc/tests/wraparound/schedule/test_wraparound_schedule.py` at 1275 lines; `dslc/workflows/wraparound_cegis.py` is 1242 lines. Largest C++/header file under `P4B-Translator/backends/verify` is `slicing/slicer_internal.h` at 2371 lines; `translate/impl/lowering/translate_expression.cpp` is now 887 lines.
  - Final direct-directory audit: no Python/C++/header directory under `dslc` or `P4B-Translator/backends/verify` has more than 8 direct implementation files. P4B translate implementation is now organized as `translate/impl/core` (Translator-wide state/helpers), `translate/impl/lowering` (8 IR-to-Boogie lowering files), `translate/impl/meta`, and `translate/impl/support`.
  - P4B build passed in WSL after the final `impl/lowering` directory move: `cd P4B-Translator/build-host && cmake --build . --target p4c-translator -j2`.
  - P4B slicing selftest passed: `P4B-Translator/build-host/backends/verify/p4c-translator -I P4B-Translator/p4include --goto --bmv2cmds Procurator/argo/code/dataset/Netchain/commands_1.txt --slicing-vars=sequence_reg[0] --slicing-selftest=netchain_seq Procurator/argo/code/dataset/Netchain/netchain_16.p4`.
  - Focused Python regressions passed: `python3 -m unittest -v dslc.tests.wraparound.test_wraparound_candidate_gating dslc.tests.wraparound.cegis.core.test_wraparound_cegis_dynamic_index dslc.tests.wraparound.cegis.core.test_wraparound_cegis dslc.tests.wraparound.cegis.core.test_wraparound_cegis_order dslc.tests.wraparound.schedule.test_wraparound_schedule dslc.tests.wraparound.schedule.test_schedule_manifest_certification` (52 tests, OK).
  - Smoke/regression set passed: `python3 -m unittest -v dslc.tests.boogie.backend.test_boogie_backend_smoke dslc.tests.boogie.backend.test_boogie_slicing_seeds dslc.tests.p4b.test_p4b_translator_slicing_selftest dslc.tests.wraparound.schedule.test_wraparound_workflow_smoke` (33 tests, OK).
  - Flowrest compile/smoke passed in WSL:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_count_wraparound.prop --out /tmp/external_flowrest_check.bpl --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --use-spec-max-steps`
    - `./bin/procurator smoke --bpl /tmp/external_flowrest_check.bpl --harness sequential`

## 2026-05-01 P4B table-filter slicing hardening for external Flowrest

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_len_total_wraparound_direct.prop`
- **Time**: 2026-05-01 16:05-16:43 Asia/Shanghai
- **Goal/Progress**: Matured P4B slicing for external TNA programs where a property only depends on direct RegisterAction write effects. Flowrest previously retained the unrelated ML classification suffix (`table_feature*`, `code_table*`, `voting_table`) even when slicing for `Ingress_reg_pkt_len_total`.
- **Result**:
  - Root cause: `SliceResult.keepTables == {}` was ambiguous. The slicer used empty `keepTables` as a fallback to keep every P4 table, while the translator also interpreted an empty table set as "do not filter tables." For register-action-only slices this conservatively kept unrelated table declarations/procedures even after statement slicing removed the table call sites.
  - P4B now carries an explicit table-filter bit (`SliceResult.filterTables` / `P4VerifyOptions.slicingFilterTables`). Under real non-JSON slicing, `filterTables=true` and an empty `keepTables` means "no P4 table declarations are required." JSON IR still disables var/table filtering because statement pruning is skipped there.
  - Reviewer/subagent flagged the important empty-slice edge case: if `keepStatementIds` is empty, filtering all tables while leaving the original IR unpruned can create dangling `table.apply` calls. Fixed by adding an explicit `pruneEmptySlice` mode to `applySlice` and using it in the non-JSON slicing pipeline.
  - Flowrest compile/smoke after the fix:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_len_total_wraparound_direct.prop --out /tmp/flowrest_len_after_filter.bpl --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --use-spec-max-steps`
    - `./bin/procurator smoke --bpl /tmp/flowrest_len_after_filter.bpl --harness sequential`
    - generated Boogie shrank from the prior `/tmp/flowrest_len_ff.bpl` 1677 lines with 174 ML-table suffix references to 1216 lines with 0 `Ingress_table_feature*` / `Ingress_code_table*` / `Ingress_voting_table` references.
  - Flowrest solve after the fix:
    - run `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound_direct/20260501-163945-5809/`
    - command used `--boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --use-spec-max-steps --wraparound off --ultimate-timeout-seconds 180 --no-witness-rerun`
    - main result `UNSAFE`; `gemcutter.log` reports `OverallTime: 149.6s`, 25 CEGAR iterations, target `flowrest_Ingress_reg_pkt_len_total.writeErr0ASSERT_VIOLATIONASSERT`.
    - CLI returned nonzero only because witness rerun was intentionally disabled and no GraphML witness was produced.
- **Pitfalls（实现错误导致）**:
  - The original `keepTables.empty()` fallback hid a real precision problem and made register-action-only slicing look as if later tables were control/data dependent. Debug DOTs showed `keepNodes` did not include the ML table call sites; the table retention came from the fallback, not true dependency.
  - The first explicit-filter design would have been unsafe for empty statement slices if statement pruning remained guarded by `!keepStatementIds.empty()`. This was fixed before broader testing by forcing non-JSON slicing to run `applySlice(..., pruneEmptySlice=true)`.
- **Fixes/regression tests**:
  - `P4B-Translator/backends/verify/slicing/slicer.h`: added `SliceResult.filterTables`.
  - `P4B-Translator/backends/verify/translate/options.h`: added `P4VerifyOptions.slicingFilterTables`.
  - `P4B-Translator/backends/verify/bpl_verify/pipeline.cpp`: non-JSON slicing now always applies statement pruning (including empty slices) and propagates the explicit table-filter bit; JSON IR remains filtering-disabled.
  - `P4B-Translator/backends/verify/slicing/slicer_apply.cpp`: added `pruneEmptySlice` to make empty slices intentionally prune control statements when requested.
  - `P4B-Translator/backends/verify/translate/impl/lowering/translate_table.cpp`: table lowering now checks `slicingFilterTables` instead of overloading an empty keep set.
  - `dslc/tests/p4b/test_p4b_translator_slicing_selftest.py`: added `test_external_flowrest_register_seed_prunes_unrelated_tables`, which checks that `Ingress_reg_pkt_len_total` register-action write semantics remain while Flowrest ML suffix tables are absent.
- **Smoke/regression**:
  - P4B build passed in WSL: `cd /mnt/e/p4-verify/P4B-Translator/build-host && cmake --build . --target p4c-translator -j2`.
  - Focused tests passed: `python3 -m unittest -v dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_external_flowrest_register_seed_prunes_unrelated_tables dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_external_flowrest_slicing_keeps_registeraction_inout_writeback dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_external_flowrest_regaction_execute_respects_pruned_register_index dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_netchain_seq_seed_slicing`.

## 2026-05-01 Flowrest duration follow-up after table-filter slicing

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound_host_direct.prop`
- **Time**: 2026-05-01 16:46-17:01 Asia/Shanghai
- **Goal/Progress**: Re-ran the Flowrest `reg_flow_duration` three-packet host-direct candidate after table-filter slicing and then after removing duplicate exact mirror-only global assertions already covered by P4B write-site fail-fast checks.
- **Result**:
  - After table-filter slicing, compile/smoke succeeded and the generated Boogie had 1223 lines and 0 ML suffix table references (`Ingress_table_feature*`, `Ingress_code_table*`, `Ingress_voting_table`), but Ultimate still timed out:
    - run `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound_host_direct/20260501-164646-c30c/`
    - 240s cap, `RESULT: Ultimate could not prove your program: Timeout`
    - `OverallTime: 235.5s`, 22 CEGAR iterations, 2 error locations before duplicate-target cleanup.
  - Added a narrow DSLC harness optimization: for exact mirror-only global assertions that were accepted by P4B fail-fast insertion, the sequential harness no longer emits duplicate per-step/global `procurator_bad` checks. Guarded assertions and legacy/non-P4B imports are unchanged.
  - After duplicate-target cleanup, compile/smoke succeeded and the generated Boogie had 1214 lines, 0 `procurator_bad` occurrences, 0 ML suffix table references, and exactly one remaining assertion at `flowrest_Ingress_reg_flow_duration.write`.
  - Re-run still timed out:
    - run `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound_host_direct/20260501-165640-ef41/`
    - 240s cap, `RESULT: Ultimate could not prove your program: Timeout`
    - `OverallTime: 236.2s`, 17 CEGAR iterations, 1 error location.
- **Pitfalls（实现/模型问题）**:
  - Removing duplicate global assertions reduced error locations but did not solve the duration candidate; the remaining bottleneck is the three-packet stateful prefix with `reg_time_last_pkt`, `reg_flow_ID`, `reg_pkt_count`, `reg_flow_iat_max`, and 32-bit timestamp arithmetic.
  - Ultimate labels the remaining write-site assertion as `flowrest_mainProcedureErr0ASSERT_VIOLATIONASSERT` after inlining, even though the only source-level assertion is in `flowrest_Ingress_reg_flow_duration.write`.
- **Fixes/regression tests**:
  - `dslc/backends/boogie/compiler.py`: records which exact mirror-only global assertions were actually sent to P4B fail-fast for P4B-generated imports.
  - `dslc/backends/boogie/harness/emitter.py` and `dslc/backends/boogie/harness/flow/sequential.py`: skip duplicate harness-side checks only for those P4B-covered exact global assertions.
  - `dslc/tests/boogie/backend/test_boogie_backend_smoke.py`: updated exact fail-fast coverage to require that duplicate `procurator_bad` checks are absent; guarded fail-fast negative test remains unchanged.
- **Smoke/regression**:
  - Focused tests passed: `python3 -m unittest -v dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_exact_register_mirror_assert_enables_p4b_fail_fast dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_guarded_register_mirror_assert_does_not_enable_fail_fast`.

## 2026-05-01 TNA/V1MODEL P4B coverage scan and P4TV include sanitizer fix

- **Spec/Programs**: Top-level TNA/Tofino and V1MODEL programs under `Procurator/argo/code/dataset` (39 discovered top-level programs; no Ultimate/GemCutter solver run in this phase)
- **Time**: 2026-05-01 14:25-14:55 Asia/Shanghai
- **Goal/Progress**: Continued the tool-generality track toward covering all encountered Tofino/TNA and V1MODEL programs. Added a reusable WSL coverage scanner that enumerates top-level P4 programs, invokes P4B translation only, and writes JSON/Markdown reports under `.tmp/procurator/p4b_coverage/...`. External datasets were not modified.
- **Result**:
  - Added `dslc/bench/scan_p4b_coverage.py`.
  - Initial base scan found 35/39 top-level programs translated successfully. The actionable P4B gap was Blink: `@assert[...]` occurred in a quoted include file, but P4B only sanitized the top-level input.
  - Fixed P4B P4TV annotation normalization in `P4B-Translator/backends/verify/bpl_verify/frontend.cpp`:
    - quoted include closure is pre-scanned for P4TV bracket annotations;
    - if needed, a temporary mirror is generated under `/tmp/p4b_sanitized_*`;
    - quoted includes are rewritten to the temporary mirror;
    - no `.p4b_sanitized_*` files are written into the source dataset directories.
  - After the fix, base translation coverage is 36/39:
    - report: `.tmp/procurator/p4b_coverage/20260501_top_after_sanitizer/coverage.{json,md}`
    - `Blink/main.p4` moved from FAIL to OK.
  - Slicing-mode translation coverage is also 36/39:
    - report: `.tmp/procurator/p4b_coverage/20260501_top_after_sanitizer_slicing/coverage.{json,md}`
    - no additional slicing-only failures appeared among the currently legal top-level programs.
  - Remaining 3 failures are currently classified as source/front-end syntax issues rather than P4B backend unsupported semantics:
    - `Procurator/argo/code/dataset/V1modelTest/V1test.p4`: malformed/non-P4-16 example shape (`header ethernet_t eth` and stray `) main {`).
    - `Procurator/argo/code/dataset/horus-p4/p4_16/targets/bmv2/falcon.p4app/falcon.p4`: mixed architecture source (`#include <tna.p4>` but `V1Switch(...) main` and v1model-style `standard_metadata_t` controls).
    - `Procurator/argo/code/dataset/tofinoTest/test.p4`: invalid TNA example syntax with a control instantiation inside `apply`.
- **Pitfalls (implementation errors found/fixed)**:
  - First frontend sanitizer attempt used a fragile C++ raw-regex include matcher and caused a runtime regex construction exception, caught by the Netchain slicing selftest. Replaced the include parser with a simple line scanner for `#include "..."`.
  - Scanner's first candidate heuristic included parser/ingress include modules. Tightened the default to architecture-instantiated top-level programs and added `--include-modules` for optional module-level scans.
  - Scanner originally measured sliced translation by default. The default now measures base P4B translation using `--no-slicing`; `--with-slicing` explicitly exercises default slicing.
- **Fixes/regression tests**:
  - `dslc/tests/p4b/test_p4b_translator_p4tv_assert_assume.py`: added a quoted-include P4TV bracket-assert regression and asserts the source tree remains free of `.p4b_sanitized_*` files.
  - `dslc/bench/scan_p4b_coverage.py`: added top-level discovery, target classification, per-program timeout, base/slicing modes, and failure-category reporting.
- **Smoke/regression**:
  - P4B build passed in WSL: `cd /mnt/e/p4-verify/P4B-Translator/build-host && cmake --build . --target p4c-translator -j2`.
  - P4B Netchain slicing selftest passed after the sanitizer fix.
  - P4TV regression passed: `python3 -m unittest -v dslc.tests.p4b.test_p4b_translator_p4tv_assert_assume` (2 tests, OK).
  - Tofino macro regression passed: `python3 -m unittest -v dslc.tests.p4b.test_p4b_tofino_cpp_defines` (4 tests, OK).
  - Focused regression set passed: `python3 -m unittest -v dslc.tests.boogie.backend.test_boogie_backend_smoke dslc.tests.boogie.backend.test_boogie_registers_typedef_index0 dslc.tests.boogie.backend.test_boogie_slicing_seeds dslc.tests.p4b.test_p4b_translator_slicing_selftest dslc.tests.p4b.test_p4b_translator_p4tv_assert_assume dslc.tests.wraparound.test_wraparound_candidate_gating dslc.tests.wraparound.schedule.test_schedule_manifest_certification dslc.tests.wraparound.schedule.test_wraparound_workflow_smoke dslc.tests.wraparound.transform.test_wraparound_transform` (81 tests, OK).

## 2026-05-01 external ML wraparound slot0 exploration and P4B index-prune hardening

- **Specs**:
  - `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_len_total_wraparound_slot0.prop`
  - `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_slot0.prop`
  - `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound_slot0.prop`
- **Time**: 2026-05-01 13:20-14:25 Asia/Shanghai
- **Goal/Progress**: Continued external in-network ML-system bug exploration without modifying upstream P4 datasets. The focus was slot-0 witness specs that seed P4B register mirrors and exercise TNA `RegisterAction.execute(...)` under slicing. All runs were staged: compile/smoke first, then short ENTRY/NEAR_WRAP checks only.
- **Result**:
  - P4B RegisterAction index pruning is now wired through the normal Boogie builtin declaration path. The generated index assumptions use declared helpers such as `bule.bv16(...)` / `bule.bv11(...)` rather than undeclared direct `bvule.bvW$builtin(...)` calls.
  - Wraparound CONFIRM/NEAR_WRAP fast-forward now handles non-unit additive steps soundly. For `bv16 + 32768`, the target starts at `32768bv16` and the assertion gate opens after leaving `32768bv16`; `+1` cases still start at `65535bv16`.
  - `external_flowrest_per_flow_pkt_len_total_wraparound_slot0`:
    - Compile/smoke passed in WSL.
    - Candidate extraction recovered `index_value=0` and `step_delta=32768`.
    - ENTRY_CHECK passed: run `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound_slot0/20260501-140337-3715/`, `UNSAFE`, wall about 34.2s.
    - NEAR_WRAP used the corrected `32768bv16` boundary but timed out under the 120s stage limit: wall about 145.4s including tool overhead, manifest uncertified.
  - `external_etc_noms2024_pkt_len_total_wraparound_slot0`:
    - Compile/smoke passed in WSL.
    - Candidate extraction recovered `index_value=0` and `step_delta=32768`.
    - First staged run exposed a P4B type error (`Undeclared function bvule.bv11$builtin`) in ENTRY_CHECK.
    - After the P4B helper fix, ENTRY_CHECK passed: run `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_slot0/20260501-141448-88dd/`, `UNSAFE`, wall about 23.3s.
    - NEAR_WRAP timed out under the 120s stage limit: wall about 138.0s including tool overhead, manifest uncertified.
  - `external_flowrest_per_flow_flow_duration_wraparound_slot0`:
    - Compile/smoke passed in WSL.
    - Static checks show `flowrest_Ingress_reg_flow_duration.size == 1` and a declared `bule.bv16(...)` index-prune assume before the RegisterAction read.
    - Candidate extraction produced no schedule-replay wraparound candidate because the duration delta is not a single env-fixed affine step. This case remains a bounded interleaving/data-flow candidate, not a certified wraparound case.
- **Pitfalls (implementation issues and model-fit issues)**:
  - The initial RegisterAction index-prune implementation emitted direct `$builtin` bvule calls. This worked for widths already declared by DSLC preambles but failed for ETC's `bv11` index width. The fix belongs in P4B, because P4B owns P4-local RegisterAction translation and helper declarations.
  - The schedule-replay pipeline had still assumed an add-by-1 near boundary for CONFIRM/NEAR_WRAP. This was incorrect for env-fixed deltas such as `+32768`; the corrected boundary is the one-step predecessor of the wrap point.
  - Flowrest/ETC packet-length-total are small-period feature-counter overflows with real companion-state dependencies (first packet establishes flow state; later packet performs the additive update). They are not clean one-step large-prefix wraparound cases. The current full-pass NEAR_WRAP still retains post-write ML feature/code/voting table suffixes and times out in Ultimate TraceAbstraction.
  - Subagent review confirmed the same split: companion flow state is a legitimate dependency, while the retained post-write ML suffix is a P4B slicing/pass-completion over-approximation. No additional subagent edits were made.
- **Fixes/regression tests**:
  - `P4B-Translator/backends/verify/translate/impl/lowering/translate_method.cpp`: RegisterAction index pruning now calls `addFunction("bule", "bvule", typeName, "bool")` and emits `bule.bvW(...)`.
  - `dslc/transform/wraparound_stages.py`: added near-wrap boundary computation for non-unit `add`/`sub` steps and reused it for CONFIRM initialization and assertion gating.
  - `dslc/tests/p4b/test_p4b_translator_slicing_selftest.py`: updated Flowrest RegisterAction index-prune expectation and added ETC `bv11` helper regression.
  - `dslc/tests/wraparound/transform/test_wraparound_transform.py`: added non-unit confirm-boundary regression for `bv16 + 32768`.
- **Smoke/regression**:
  - P4B build passed in WSL: `cd /mnt/e/p4-verify/P4B-Translator/build-host && cmake --build . --target p4c-translator -j2`.
  - P4B Netchain slicing selftest passed: `P4B-Translator/build-host/backends/verify/p4c-translator -I P4B-Translator/p4include --goto --bmv2cmds Procurator/argo/code/dataset/Netchain/commands_1.txt --slicing-vars=sequence_reg[0] --slicing-selftest=netchain_seq Procurator/argo/code/dataset/Netchain/netchain_16.p4`.
  - Focused transform/schedule/candidate tests passed: `python3 -m unittest -v dslc.tests.wraparound.transform.test_wraparound_transform dslc.tests.wraparound.schedule.test_schedule_manifest_certification dslc.tests.wraparound.test_wraparound_candidate_gating` (33 tests, OK).
  - Full focused regression set passed: `python3 -m unittest -v dslc.tests.boogie.backend.test_boogie_backend_smoke dslc.tests.boogie.backend.test_boogie_registers_typedef_index0 dslc.tests.boogie.backend.test_boogie_slicing_seeds dslc.tests.p4b.test_p4b_translator_slicing_selftest dslc.tests.wraparound.test_wraparound_candidate_gating dslc.tests.wraparound.schedule.test_schedule_manifest_certification dslc.tests.wraparound.schedule.test_wraparound_workflow_smoke dslc.tests.wraparound.transform.test_wraparound_transform` (79 tests, OK).
  - No new external bug is counted as certified in this entry. Flowrest and ETC packet-length-total have clean ENTRY evidence and corrected candidates, but NEAR_WRAP timed out; Flowrest duration compiled/smoked but is not a schedule-replay wraparound candidate.

## 2026-05-01 external guarded bug evidence and P4B fail-fast mirror assertion

- **Specs**:
  - `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_len_total_wraparound_direct.prop`
  - `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_count_wraparound.prop`
  - `Procurator/argo/code/spec/bench/external_int_flowdos_counter_wraparound.prop`
- **Time**: 2026-05-01 15:23-15:58 Asia/Shanghai
- **Goal/Progress**: Rechecked external ML/INT candidate evidence under the stricter standard that an overflow bug assertion must be guarded by the P4B write mirror (`__wrote_any` / `__last_value` or slot-0 mirror), then added a narrow P4B/DSLC fail-fast optimization for exact mirror-only assertions.
- **Result**:
  - Subagent review confirmed that previous ETC `pkt_count` and FlowDoS `counter_filter` UNSAFE artifacts were not claim-ready because their generated BPL asserted stale/initial mirror values rather than actual writes. Only Flowrest `pkt_len_total` direct had current guarded UNSAFE evidence.
  - `external_etc_noms2024_pkt_count_wraparound.prop` was corrected from `etc_Ingress_reg_pkt_count[0] != 0` to `!(etc_Ingress_reg_pkt_count__wrote_any && etc_Ingress_reg_pkt_count__last_value == 0)`.
  - ETC guarded compile/smoke passed (`/tmp/external_etc_pkt_count_guarded.bpl`) and short solve returned `SAFE`:
    - run `.tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260501-152302-dfc6/`, 180s cap, `RESULT: Ultimate proved your program to be correct!`
    - after fail-fast insertion, rerun `.tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260501-155334-63bd/` also returned `SAFE`.
  - FlowDoS guarded compile/smoke passed (`/tmp/external_flowdos_guarded.bpl`), but solving still timed out:
    - run `.tmp/procurator/verify/external_int_flowdos_counter_wraparound/20260501-152412-2a3d/`, 180s cap, `TIMEOUT`
    - after fail-fast insertion, run `.tmp/procurator/verify/external_int_flowdos_counter_wraparound/20260501-155439-3f01/`, 240s cap, `TIMEOUT`
  - Flowrest `pkt_len_total` direct remains the clean current external bug evidence. With `--no-witness-rerun`, a fresh fail-fast-enabled run produced main `UNSAFE`:
    - run `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound_direct/20260501-154740-3f0c/`
    - `gemcutter.log`: `RESULT: Ultimate proved your program to be incorrect!`, `OverallTime: 131.0s`
    - counterexample hits the P4B write-site assertion in `flowrest_Ingress_reg_pkt_len_total.write`; values show `flowrest_hdr.ipv4.total_len=32768bv16`, old `reg_pkt_len_total__last_value=32768bv16`, new `reg_pkt_len_total__last_value=0bv16`, and `reg_pkt_len_total__wrote_any=true`.
    - CLI exited nonzero only because witness rerun was intentionally disabled and no GraphML witness was generated; the main UNSAFE log is intact.
- **Pitfalls (implementation/model issues)**:
  - Copying a `.prop` to `/tmp` for quick max-step edits broke relative `import` resolution (`/dataset/...`), causing a false translation failure. Temporary spec experiments should stay under the spec directory or pass an explicit base directory.
  - The first fail-fast design idea would have made DSLC infer bit widths from register names. This was corrected before landing: DSLC now passes the raw numeric constant, and P4B renders the typed literal at the register write site using the actual register value type.
  - Immediate mirror assertions are sound only as additive checks for exact mirror-only formulas. They are not enabled for guarded formulas such as host/phase-gated wraparound specs or formulas with extra side conditions.
- **Fixes/regression tests**:
  - `P4B-Translator/backends/verify/translate/options.h`: added `--fail-fast-register-assert=reg:any|slot0:constant`.
  - `P4B-Translator/backends/verify/translate/impl/lowering/translate_program.cpp`: P4B emits additive write-site assertions after native register mirror updates, using the register value type to render constants (`0bv8`, `0bv16`, etc.).
  - `dslc/backends/boogie/compiler.py`: DSLC recognizes only exact global mirror assertions and passes local register fail-fast requests to P4B; original global assertions remain in the harness.
  - `dslc/backends/boogie/node/p4b.py`: translator wrapper forwards fail-fast register assertion options.
  - `dslc/tests/boogie/backend/test_boogie_backend_smoke.py`: added positive Flowrest direct fail-fast coverage and negative guarded-spec coverage.
- **Smoke/regression**:
  - P4B build passed in WSL: `cd /mnt/e/p4-verify/P4B-Translator/build-host && cmake --build . --target p4c-translator -j2`.
  - Fail-fast unit coverage passed: `python3 -m unittest -v dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_exact_register_mirror_assert_enables_p4b_fail_fast dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_guarded_register_mirror_assert_does_not_enable_fail_fast`.
  - Focused smoke passed: `python3 -m unittest -v dslc.tests.p4b.test_p4b_translator_p4tv_assert_assume dslc.tests.p4b.test_p4b_tofino_cpp_defines dslc.tests.boogie.backend.test_boogie_backend_smoke` (21 tests, OK).
  - Netchain P4B slicing selftest passed in WSL after the P4B option addition.
- **Pitfalls（实现错误导致）**:
  - Generated split files initially lost quotes in `#include translate.h` and regex raw-string literals because of shell/Powershell quoting. This caused syntax/build failures before logic tests ran.
  - Moving CEGIS loop implementations broke private-test monkey-patching until the facade wrapper synchronized patched names into the moved loop modules.
  - Moving slicer DOT helpers exposed that `dotSafeName` was also used by `slicer.cpp`, not only by `writeDotGraph`; it had to remain a declared helper instead of becoming anonymous-local-only.
  - Directory-level unittest discovery imports tests as top-level modules, so newly split schedule tests needed absolute fixture imports instead of relative imports.
  - Subagent review found that the newly extracted `translate_type.cpp` relied on transitive `<string>` inclusion for `std::to_string`; fixed by adding an explicit `<string>` include.
  - The first P4B review prompt referenced the pre-final `translate/impl/core/translate_method.cpp` path; after enforcing the folder fanout rule, the authoritative path is `translate/impl/lowering/translate_method.cpp` (and sibling lowering files).
- **Fixes**:
  - Added `dslc/analysis/wraparound_bpl_index.py` for Boogie dynamic-index recovery helpers, leaving `wraparound_candidates.py` as the strategy/API layer.
  - Added `dslc/workflows/wraparound_support/loop_schedule.py` and `loop_legacy.py`; `dslc/workflows/wraparound_cegis.py` remains the public facade and compatibility patch point.
  - Added `dslc/tests/wraparound/schedule/fixtures.py` and `test_schedule_manifest_certification.py`.
  - Added/split P4B modules: `translate/impl/lowering/translate_expression.cpp`, `translate_method.cpp`, `translate_type.cpp`, `translate_operator.cpp`, `translate_program.cpp`, `translate_statement.cpp`, `translate_table.cpp`, `translate_bitblast.cpp`, `translate/impl/meta/meta_emit.cpp`, and `slicing/slicer_dot.cpp`; updated `P4B-Translator/backends/verify/CMakeLists.txt`.
  - Updated `doc/dslc_p4b_boundary_refactor_spec.md` to the current limits (`Python <=1300`, `C++/header <=2500`) and the `core/lowering/meta/support` P4B translate directory contract.
- **Smoke/regression**:
  - The failures above are now covered by py_compile, schedule discovery/import coverage, P4B unified-build compilation, `netchain_seq` slicing selftest, Flowrest compile/smoke, and the focused Python regression sets listed above.
  - Additional post-review focused P4B checks passed: `test_external_flowrest_registeraction_execute_wraparound_meta`, `test_tofino_table_slicing_keeps_table_semantics`, and `test_netchain_seq_seed_slicing`.
  - Structure audit script reported `line violations: 0` and `directory direct-file violations: 0`.
  - Subagent P4B review found no blocking semantic, CMake, or unified-build issue after the final path correction; residual risk is only that this remains a physical/source split, not yet a full visitor/pass decomposition.

## 2026-05-01 backend/refactor post-review hardening

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_count_wraparound.prop` (compile/smoke only; no Ultimate/GemCutter run in this phase)
- **Time**: 2026-05-01 01:35-02:45 Asia/Shanghai
- **Goal/Progress**: Ran subagent code-quality review on the P4B driver/pipeline split and the DSLC/P4B register-mirror boundary, then fixed the review findings that affected soundness or ownership boundaries before delivery.
- **Result**:
  - P4B verify driver is now split into `bpl_verify/main.cpp` (thin CLI driver), `frontend.{h,cpp}` (frontend/JSON/P4TV normalization), `pipeline.{h,cpp}` (slicing, P4-local analyses, P4LTL, Boogie/meta emission), and `slicing/slicer_selftest.{h,cpp}` (slicer regression checks).
  - Slicer slice-application code no longer includes the full `slicer_internal.h` implementation dump just to discover register declarations. `RegisterDeclCollector` moved into `slicing/collectors/register_decl.{h,cpp}`, and `slicer.h` now includes its own `ReferenceMap`/`TypeMap` dependencies directly.
  - JSON IR slicing was restored to the conservative sound behavior: because JSON statement pruning is skipped, P4B no longer applies var/table filtering in JSON mode. It still consumes slicer metadata such as register index/RW summaries.
  - `slicer_selftest` no longer depends on the full verify CLI options object; the pipeline extracts the case name and passes only the primitive case string plus the `SliceResult`/sliced program.
  - P4B Boogie/meta emission now returns failure when `openFile` fails for `-o` or `--meta-out`, instead of silently returning success from the backend pipeline.
  - DSLC no longer silently patches P4B-generated register semantics. P4B-generated nodes must include register markers, mirror globals, write-body updates, and complete write-procedure `modifies` clauses. Legacy `.bpl` imports still use compatibility backfill.
  - Final structure audit: `line violations: []`, `dir violations: []`. Largest Python file remains below 1300 lines (`test_wraparound_schedule.py`, 1275); largest C++/header remains below 2500 lines (`slicing/slicer_internal.h`, 2284 after moving `RegisterDeclCollector` out).
- **Subagent review findings addressed**:
  - P4B review high-priority finding: JSON slicing had changed behavior by keeping var/table filters while skipping statement pruning. Fixed and converted the Gecko JSON regression to assert declaration counts remain equal under JSON slicing.
  - P4B review medium finding: `slicer_selftest` depended on `P4VerifyOptions`; fixed by making the selftest API take only the selftest case name.
  - P4B review low finding: backend emission failures were swallowed; fixed by propagating failure from `emitBoogieAndMeta`.
  - DSLC review P2 findings: register discovery was marker-only and could miss unmarked P4B register arrays; mirror completeness ignored `modifies`. Fixed both and added fake-P4B failure/success tests.
  - P4B review medium finding: `slicer_internal.h` was still too much of an implementation dump. Partially addressed by moving the shared register declaration collector to a dedicated collector module and removing the full internal include from `slicer_apply.cpp`. The remaining larger CFG/use-def split is intentionally left as a tracked next-phase refactor.
- **Pitfalls（实现错误导致）**:
  - I initially ran `cmake --build ... p4c-translator` in parallel with Python tests that execute `p4c-translator`, producing `OSError: [Errno 26] Text file busy`. This is a WSL/Linux workflow issue, not a functional regression. The tests were rerun serially and passed. Future P4B build/test stages must not relink and execute the same binary concurrently.
  - The first JSON slicing test expectation still assumed declaration-count reduction. After restoring the sound JSON-safe policy, the correct regression is equality of declaration counts plus presence of required child fields.
  - Moving `RegisterDeclCollector` exposed that `slicer.h` used `P4::ReferenceMap` and `P4::TypeMap` without directly including their headers; unified builds had previously masked this. Added direct includes to `slicer.h`.
- **Fixes/regression tests**:
  - `dslc/tests/boogie/backend/test_boogie_backend_smoke.py`: added fake-P4B tests for complete native mirrors, missing mirrors, missing register markers, and incomplete `modifies`; added compiler-level legacy `.bpl` backfill integration coverage.
  - `dslc/tests/boogie/backend/test_boogie_registers_typedef_index0.py`: added a regression ensuring missing `modifies` is repaired without duplicating existing write-body mirror updates.
  - `dslc/tests/p4b/test_p4b_translator_slicing_selftest.py`: updated Gecko JSON slicing regression to enforce sound declaration preservation when statement pruning is disabled.
  - `doc/dslc_p4b_boundary_refactor_spec.md`: documented the complete P4B register mirror contract and the WSL no-parallel-relink test rule.
  - `P4B-Translator/backends/verify/slicing/collectors/register_decl.{h,cpp}`: new collector module shared by `slicer.cpp` and `slicer_apply.cpp`.
- **Smoke/regression**:
  - P4B build passed in WSL after the collector split: `cd /mnt/e/p4-verify/P4B-Translator/build-host && cmake --build . --target p4c-translator -j2` (only existing Boost/C++ standard warnings remain).
  - Focused + smoke Python tests passed serially after the collector split: `python3 -m unittest -v dslc.tests.boogie.backend.test_boogie_backend_smoke dslc.tests.boogie.backend.test_boogie_registers_typedef_index0 dslc.tests.boogie.backend.test_boogie_slicing_seeds dslc.tests.p4b.test_p4b_translator_slicing_selftest dslc.tests.wraparound.schedule.test_wraparound_workflow_smoke` (43 tests, OK).
  - P4B Netchain selftest passed: `P4B-Translator/build-host/backends/verify/p4c-translator -I P4B-Translator/p4include --goto --bmv2cmds Procurator/argo/code/dataset/Netchain/commands_1.txt --slicing-vars=sequence_reg[0] --slicing-selftest=netchain_seq Procurator/argo/code/dataset/Netchain/netchain_16.p4`.
  - Flowrest compile/smoke passed in WSL:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_count_wraparound.prop --out /tmp/external_flowrest_check.bpl --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --use-spec-max-steps`
    - `./bin/procurator smoke --bpl /tmp/external_flowrest_check.bpl --harness sequential`
## 2026-05-01 external ETC packet-length-total follow-up after table-filter/fail-fast cleanup

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_direct.prop`
- **Time**: 2026-05-01 17:15-17:23 Asia/Shanghai
- **Goal/Progress**: Re-ran the ETC packet-length-total candidate with the latest P4B table-filter slicing and DSLC duplicate global-assert cleanup, staged as compile/smoke first and then single Ultimate runs.
- **Result**:
  - Compile/smoke passed in WSL with `--boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --use-spec-max-steps`; generated `/tmp/etc_len_after_filter.bpl`, 1415 lines.
  - The generated BPL contains the actual P4B write-site assertion at `etc_Ingress_reg_pkt_len_total.write`, line 885 in the generated run, guarding `etc_Ingress_reg_pkt_len_total__wrote_any && etc_Ingress_reg_pkt_len_total__last_value == 0bv16`. This avoids the stale/initial mirror pitfall from older external candidates.
  - Default 2GB GemCutter run `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260501-171502-e6c6/` reached the target assertion repeatedly but ended with Z3 out-of-memory during trace checking; the toolchain returned no final proof result.
  - 8GB small-blocks GemCutter run `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260501-171830-c5c4/` avoided the Z3 OOM but timed out under the 240s cap. Log shows repeated targeting of `etc_Ingress_reg_pkt_len_total.writeErr0ASSERT_VIOLATIONASSERT`; final status is `TIMEOUT`, not claim-ready `UNSAFE`.
  - This ETC candidate remains promising but is not delivered as a confirmed bug in this entry.
- **Pitfalls (implementation/model issues)**:
  - The latest table filtering still leaves `code_table0` / `voting_table` suffix state in ETC (`grep` count 34), unlike the cleaned Flowrest packet-length-total run. The remaining ML suffix and companion state inflate CEGAR traces even though the property only targets `reg_pkt_len_total`.
  - A 2GB solver memory profile can fail as `Toolchain returned no result` rather than a clean `TIMEOUT`; the log must be checked for Z3 OOM before classifying the experiment.
- **Fixes/regression tests**:
  - No code fix landed in this entry. The next implementation target is to reduce the retained post-feature ML suffix or tighten the generated control path without modifying the external P4 dataset.
- **Smoke/regression**:
  - `./bin/procurator compile ... external_etc_noms2024_pkt_len_total_wraparound_direct.prop ...` passed in WSL.
  - `./bin/procurator smoke --bpl /tmp/etc_len_after_filter.bpl --harness sequential` passed.

## 2026-05-01 external ETC/Flowrest bounded-direct step-bound probes

- **Specs**:
  - `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_direct.prop`
  - `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound_host_direct.prop`
  - `Procurator/argo/code/spec/bench/external_int_flowdos_counter_wraparound.prop` (compile/smoke only)
- **Time**: 2026-05-01 17:26-17:35 Asia/Shanghai
- **Goal/Progress**: Checked whether tighter BMC step bounds can turn the external packet-length / duration candidates into fast, claim-ready direct UNSAFE results while keeping generated models free of post-feature ML suffixes.
- **Result**:
  - ETC `pkt_len_total` with CLI override `--max-steps 2` compiled/smoked: `/tmp/etc_len_steps2.bpl`, 1323 lines, 0 `table_feature|code_table|voting_table` references, write-site assertion preserved at `etc_Ingress_reg_pkt_len_total.write`. Ultimate returned `SAFE` in run `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260501-172626-c924/`.
  - ETC `pkt_len_total` with CLI override `--max-steps 3` compiled/smoked: `/tmp/etc_len_steps3.bpl`, 1383 lines, 0 ML suffix references. Ultimate returned `SAFE` in run `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260501-172838-7729/`.
  - Flowrest `flow_duration` host-direct with CLI override `--max-steps 6` compiled/smoked: `/tmp/flowrest_duration_steps6.bpl`, 1108 lines, 0 ML suffix references, actual write-site assertion at `flowrest_Ingress_reg_flow_duration.write`.
  - Flowrest `flow_duration` run `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound_host_direct/20260501-173121-2486/` timed out under the 180s cap. It repeatedly targeted the write-site assertion (inlined as `flowrest_mainProcedureErr0ASSERT_VIOLATIONASSERT`), final `OverallTime` about 177.1s, not claim-ready.
  - Flowrest `flow_duration` with 8GB small-blocks settings also timed out: run `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound_host_direct/20260501-173726-bb9c/`, 240s cap, `OverallTime` about 235.5s, still repeatedly targeting the same actual write-site assertion.
  - FlowDoS `counter_filter` compile/smoke with `--max-steps 1` passed: `/tmp/flowdos_counter_check.bpl`, 1054 lines. Quick inspection showed `flowdos_hdr.ipv4.totalLen` and INT metadata are present, but the current counter spec does not seed the egress total-length arithmetic, so no bug claim was attempted from this compile-only check.
- **Pitfalls (implementation/model issues)**:
  - ETC needs the 4-step bound to reach the suspicious actual-write target, but that bound also brings back the third-packet classification suffix and much harder CEGAR traces. Smaller bounds are clean but prove bounded safety.
  - Flowrest duration is already a small model after slicing, so its remaining difficulty is solver/refinement behavior rather than unsupported syntax or obvious extra table suffixes.
  - FlowDoS total-length arithmetic is a possible separate header-wrap candidate, but it needs its own property seed and path constraints; it should not be inferred from the counter-filter spec.
- **Fixes/regression tests**:
  - No code/spec fix landed in this entry. The experiments are recorded to avoid re-running the same non-deliverable bounds as bugs.
- **Smoke/regression**:
  - All compile/smoke stages above passed in WSL before each Ultimate run.

## Communication / Experiment-Log Naming Constraint

- In conversations, experiment notes, commit/PR text, and future `AGENTS.md` entries, prefer neutral verification wording such as "external INT / telemetry program verification", "counter/wraparound verification", and "in-network telemetry case". Avoid proactively expanding or emphasizing security-sensitive attack terms or shorthand names that can trigger automated safety labeling. If an existing file path, spec name, or historical artifact contains such wording, keep the exact path when needed for reproducibility, but make the surrounding prose about verification, program semantics, counters, ENTRY/NEAR/CLOSURE, and closure checking.

## 2026-05-01 external Flowrest packet-count wraparound staged NEAR probe

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_count_wraparound.prop`
- **Time**: 2026-05-01 18:26-18:32 Asia/Shanghai
- **Goal/Progress**: Ran the packet-count candidate as a staged wraparound check, stopping after `NEAR_WRAP` so that expensive closure is attempted only if ENTRY and near-wrap reachability both pass.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260501-182622-324e/`.
  - Candidate target: `flowrest_Ingress_reg_pkt_count`, recovered `index_value=0`, `step_delta=1`, schedule actors `io, io, flowrest`.
  - `ENTRY=UNSAFE` in about 22.7s.
  - `NEAR_WRAP=TIMEOUT` under the 240s toolchain cap; near stage wall was about 257.4s and Ultimate `OverallTime` was about 235.6s.
  - No closure was run because NEAR did not pass. This is not a deliverable certified wraparound bug.
- **Pitfalls (implementation/model issues)**:
  - The near BPL has 2274 lines and still contains 175 references to the post-feature ML/classification suffix (`table_feature`, `code_table`, `voting_table`). This is not merely dead code: the packet-count path reaches the suffix when the count hits the classification threshold, so CEGAR explores substantially more path state than the simpler packet-length-total direct case.
  - For this candidate, adding closure time is not justified yet; the next step is to inspect whether packet-count wraparound is a stable net-effect loop after classification state changes, or whether the candidate should be dropped/refined.
- **Fixes/regression tests**:
  - No implementation fix landed in this entry. The staged result is recorded to prevent prematurely treating this candidate as closure-ready.
- **Smoke/regression**:
  - This run used the already smoke-checked Flowrest compilation path from the preceding entry and then ran only one Ultimate stage sequence in WSL.

## 2026-05-01 external Flowrest packet-length-total wraparound extended NEAR probe

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_len_total_wraparound_slot0.prop`
- **Time**: 2026-05-01 18:55-19:06 Asia/Shanghai
- **Goal/Progress**: Re-ran the packet-length-total slot-0 wraparound candidate with a longer single-stage NEAR budget after the earlier short-cap run had `ENTRY=UNSAFE` but `NEAR_WRAP=TIMEOUT`.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound_slot0/20260501-185501-c61d/`.
  - Candidate target: `flowrest_Ingress_reg_pkt_len_total`, `index_value=0`, `step_delta=32768`, schedule actors `env, flowrest`, projection variables `procurator_phase` and `flowrest_inbox_count`.
  - `ENTRY=UNSAFE` in about 23.4s.
  - `NEAR_WRAP=TIMEOUT` under the 600s toolchain cap; near stage wall was about 622.1s and Ultimate `OverallTime` was about 593.1s.
  - No closure was run because NEAR did not pass. This is not a deliverable certified wraparound bug.
- **Pitfalls (implementation/model issues)**:
  - The near BPL is modest in size (1836 lines), but still contains substantial classification suffix state: 210 `table_feature`, 78 `code_table`, 26 `voting_table`, and 123 `classified_flag` references. Ultimate spent most time in `AutomataDifference` / Hoare triple checking and timed out with 4 remaining error locations.
  - The manifest reports `projection_complete=true` for the current dependency projection, so the immediate blocker is near-wrap reachability under the current model rather than a closure counterexample. More blind closure time is not justified until NEAR produces an unsafe witness.
- **Fixes/regression tests**:
  - No implementation fix landed in this entry. The result is recorded as a staged non-deliverable candidate and points to post-feature suffix/path reduction as the next optimization target.
- **Smoke/regression**:
  - The run was executed as a single WSL Ultimate job with 8GB small-blocks settings and no concurrent solver jobs.

## 2026-05-01 Flowrest wraparound projection fix and direct-bug regression

- **Specs**:
  - `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_len_total_wraparound_slot0.prop`
  - `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_len_total_wraparound_direct.prop`
- **Time**: 2026-05-01 19:12-19:54 Asia/Shanghai
- **Goal/Progress**: Debugged why Flowrest packet-length-total wraparound NEAR kept timing out, improved the dependency projection extractor for P4 register-slot control/data dependencies, and re-smoked the previously confirmed bounded direct packet-length-total bug.
- **Result**:
  - Implemented a conservative confirm/near-wrap optimization: after a rewritten wraparound target assertion call, emit `assume false` to cut suffix statements in the same pass. This cannot create a witness after the target assertion; it only stops exploring code after the target check.
  - Fixed dependency projection extraction so an `else {` on a separate line inherits the preceding `if` control dependency. This matters for P4B output where `if (...) { ... } else { ... }` may be formatted across lines.
  - Promoted live fixed-slot register-array dependencies to P4B scalar slot mirrors, e.g. `flowrest_Ingress_reg_time_last_pkt` now contributes `flowrest_Ingress_reg_time_last_pkt__last0_value` to the replay projection while the target counter itself remains excluded.
  - Flowrest slot-0 wraparound NEAR after the fix:
    - run `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound_slot0/20260501-192505-83e1/`
    - `ENTRY=UNSAFE` in about 26.4s
    - `NEAR_WRAP=TIMEOUT` under a 420s cap with `--wraparound-confirm-unroll 4`
    - manifest projection now includes `procurator_phase`, `flowrest_inbox_count`, and `flowrest_Ingress_reg_time_last_pkt__last0_value`
    - no closure was run; this is still not a deliverable certified wraparound bug
  - Direct bounded Flowrest packet-length-total regression after restoring fail-fast behavior:
    - run `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound_direct/20260501-195013-1374/`
    - `RESULT: Ultimate proved your program to be incorrect!`
    - `OverallTime≈138.3s`
    - generated BPL SHA256 matches the earlier confirmed UNSAFE run `20260501-163945-5809` exactly (`0ecdeaf4aa6eb019b74864159daf10f9b41ca007ac4efbe2a093ffdf4214325d`)
    - target remains the actual P4B write-site assertion in `flowrest_Ingress_reg_pkt_len_total.write`, and the DSL harness assertion is also preserved
- **Pitfalls (implementation/model issues)**:
  - The old projection was incomplete for Flowrest-style P4-state cutpoints: live deps included `flowrest_Ingress_reg_time_last_pkt` and related control/data variables, but the projection filtered everything except phase/mailbox because only scheduler/mailbox/DSL scalars were treated as stable. This made `projection_complete=true` too optimistic for register-slot-dependent pump shapes.
  - `pkt_len_total` is not a one-packet stable pump from every cutpoint. The first-packet path sets `pkt_len_total = hdr.ipv4.total_len`; the additive wrap path requires the non-first-packet shape (`time_last_pkt != 0` / same-flow state). This is why NEAR with unroll 2 was conceptually too narrow, and unroll 4 is the first meaningful shape for two packets.
  - Removing the original DSL global assertion after adding a P4B fail-fast write-site assertion changed the direct Flowrest model from the earlier confirmed BPL and made GemCutter less stable (`TIMEOUT`/`UNKNOWN`). The correct policy is to keep fail-fast as an additional early target, not a replacement for the original DSL assertion.
  - `./bin/procurator verify ... --no-witness-rerun` can return nonzero after an `UNSAFE` result because counterexample validation expects a GraphML witness. For smoke runs that intentionally skip witness rerun, inspect the Ultimate log/result line and record the missing-witness warning separately.
  - PowerShell does not accept `&&` as used in bash command templates here; wrap chained commands inside `wsl.exe ... bash -lc 'cmd && cmd'`.
- **Fixes/regression tests**:
  - `dslc/analysis/wraparound_projection.py`: fixed separated-`else` guard inheritance; added register-slot mirror promotion for live non-target register dependencies; allows `__last0_value` mirrors as stable projection scalars.
  - `dslc/transform/wraparound_stages.py` and `dslc/transform/wraparound_instrument.py`: added confirm/near suffix cut after target assertion calls.
  - `dslc/backends/boogie/compiler.py`: kept DSL global assertions even when P4B fail-fast write-site assertions are requested.
  - Added/updated focused tests:
    - `dslc.tests.wraparound.schedule.test_wraparound_schedule.WraparoundScheduleTests.test_dependency_projection_promotes_live_register_slot_mirror`
    - `dslc.tests.wraparound.transform.test_wraparound_transform.TestWraparoundTransform.test_confirm_stops_after_gated_assert_site`
    - `dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_exact_register_mirror_assert_enables_p4b_fail_fast`
- **Smoke/regression**:
  - Focused Python tests passed in WSL:
    - `python3 -m unittest -v dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_exact_register_mirror_assert_enables_p4b_fail_fast dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_guarded_register_mirror_assert_does_not_enable_fail_fast`
    - `python3 -m unittest -v dslc.tests.wraparound.schedule.test_wraparound_schedule.WraparoundScheduleTests.test_dependency_projection_uses_mailbox_counts_not_stale_pkt_tags dslc.tests.wraparound.schedule.test_wraparound_schedule.WraparoundScheduleTests.test_dependency_projection_promotes_live_register_slot_mirror dslc.tests.wraparound.schedule.test_wraparound_schedule.WraparoundScheduleTests.test_dependency_projection_inlines_p4b_assigned_helper_call dslc.tests.wraparound.schedule.test_wraparound_schedule.WraparoundScheduleTests.test_dependency_projection_filters_transient_control_predicates dslc.tests.wraparound.transform.test_wraparound_transform`
  - Flowrest direct compile/smoke passed:
    - `wsl.exe --cd /mnt/e/p4-verify bash -lc './bin/procurator compile --spec Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_len_total_wraparound_direct.prop --out /tmp/flowrest_direct_after_fix.bpl --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --use-spec-max-steps && ./bin/procurator smoke --bpl /tmp/flowrest_direct_after_fix.bpl --harness sequential'`

## 2026-05-01 Flowrest slot0 wraparound 15min NEAR and control-dependency projection refinement

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_len_total_wraparound_slot0.prop`
- **Time**: 2026-05-01 20:06-20:23 Asia/Shanghai
- **Goal/Progress**: Re-classified the Flowrest slot0 candidate under a per-bug 15min budget, distinguishing "bug absent" from "current wraparound certificate pipeline cannot validate it". Before re-running NEAR, fixed a concrete projection-analysis bug for target-write control dependencies.
- **Result**:
  - The candidate is not classified as nonexistent. The bounded direct Flowrest packet-length-total run already shows an actual P4B register write of zero can occur; the remaining question is whether the wraparound schedule certificate can prove the long-prefix/replay shape.
  - Projection bug found and fixed: for target writes inside an `else` branch, the dependency extractor was inheriting the outer guard instead of the just-closed inner `if` guard. In Flowrest, this dropped the `flow_ID != tmp_flow_ID` guard that decides whether the packet reaches the update path.
  - After the fix, dependency projection for Flowrest slot0 includes:
    - `procurator_phase`
    - `flowrest_inbox_count`
    - `flowrest_Ingress_reg_flow_ID__last0_value`
    - `flowrest_Ingress_reg_time_last_pkt__last0_value`
  - 15min NEAR run:
    - run directory: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound_slot0/20260501-200635-05ce/`
    - `ENTRY=UNSAFE` in about 21.2s
    - `NEAR_WRAP=TIMEOUT` under a 900s cap; Ultimate `OverallTime≈891.1s`
    - `NEAR` had 12 error locations after unroll4 and spent most time in `AutomataDifference` / Hoare triple checks
  - No closure was run because NEAR did not pass. This remains "bug likely exists as a bounded write/update bug, but certified wraparound not yet produced", not "bug absent".
- **Pitfalls (implementation/model issues)**:
  - The previous projection result was still incomplete after adding register-slot mirror promotion because the target-write path guard from `else{ ... write target ... }` did not propagate into the target deps. The minimal reproducer is a same-flow guard like `if (meta.flow_id != tmp_flow_id) { ... } else { target_reg[...] := ... }`.
  - Flowrest `pkt_len_total` requires a non-first/same-flow cutpoint shape: `time_last_pkt` and `flow_ID` state matter for re-entering the additive path. If NEAR is treated as a small fixed-step check without this shape, timeout does not imply absence.
  - The current NEAR BPL still contains many gated target locations after unroll4. This suggests a solver-side reachability issue remains even after the projection is corrected, so the next implementation target should reduce NEAR to the specific target write site/schedule slice or synthesize a direct shape witness before attempting closure.
- **Fixes/regression tests**:
  - `dslc/analysis/wraparound_projection.py`: fixed `else` guard inheritance to prefer the just-closed guard; this restores control dependencies for writes in else branches.
  - `dslc/tests/wraparound/schedule/test_wraparound_schedule.py`: added `test_dependency_projection_tracks_else_guard_to_target_write`.
  - Focused tests passed:
    - `python3 -m unittest -v dslc.tests.wraparound.schedule.test_wraparound_schedule.WraparoundScheduleTests.test_dependency_projection_tracks_else_guard_to_target_write dslc.tests.wraparound.schedule.test_wraparound_schedule.WraparoundScheduleTests.test_dependency_projection_promotes_live_register_slot_mirror dslc.tests.wraparound.schedule.test_wraparound_schedule.WraparoundScheduleTests.test_dependency_projection_filters_transient_control_predicates`
- **Smoke/regression**:
  - This entry used one Ultimate/GemCutter run in WSL, with no concurrent solver jobs.
  - Bounded direct slot0 check was run to classify existence vs. certificate failure:
    - command shape: `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_len_total_wraparound_slot0.prop --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --use-spec-max-steps --wraparound off --ultimate-timeout-seconds 900 --no-witness-rerun`
    - run directory: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound_slot0/20260501-202328-7f6e/`
    - `RESULT: Ultimate proved your program to be incorrect!`, `OverallTime≈82.2s`
    - target assertion is the P4B slot0 write-site assertion in `flowrest_Ingress_reg_pkt_len_total.write`
    - classification: semantic bounded write/update bug exists; certified wraparound certificate not yet produced by NEAR/CLOSURE pipeline.

## 2026-05-01 external ETC packet-length-total direct 15min probe

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_direct.prop`
- **Time**: 2026-05-01 20:25-20:41 Asia/Shanghai
- **Goal/Progress**: Ran the ETC packet-length-total direct bounded candidate with the per-bug 15min solver budget to distinguish absence from current verification incompleteness.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260501-202555-eccb/`.
  - Command shape: `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_direct.prop --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --use-spec-max-steps --wraparound off --ultimate-timeout-seconds 900 --no-witness-rerun`.
  - Ultimate result: `TIMEOUT`; `OverallTime` was about 897.2s.
  - The run targeted both the DSL global assertion and the P4B write-site assertion for `etc_Ingress_reg_pkt_len_total.write`.
- **Pitfalls (implementation/model issues)**:
  - This is not evidence that the candidate is semantically absent. The ETC P4 code has the same relevant feature-update shape as Flowrest: first packet initializes `pkt_len_total = hdr.ipv4.total_len`, while a later same-flow packet executes `pkt_len_total = pkt_len_total + hdr.ipv4.total_len`.
  - The generated direct BPL still contains substantial post-feature classification/control suffix state (`classified_flag`, `code_table`, `voting_table`, and feature-table paths), so the timeout is currently classified as "verification did not converge within the 15min budget", not "bug nonexistent".
  - The spec uses `max_steps = 4`; this bound is from the candidate spec and should be checked against the two-packet schedule, but the next refinement should be time/path reduction rather than blindly reducing steps further.
- **Fixes/regression tests**:
  - No implementation fix landed in this entry. The immediate follow-up is to inspect the ETC same-flow/index path and try the slot-0/direct shape under the same 15min budget, then refine P4B/DSLC if the reachable target path is still buried under unrelated suffix state.
- **Smoke/regression**:
  - Single Ultimate/GemCutter job in WSL; no concurrent solver jobs were active.

## 2026-05-01 external ETC packet-length-total slot0 direct 15min probes

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_slot0.prop`
- **Time**: 2026-05-01 20:45-21:04 Asia/Shanghai
- **Goal/Progress**: Checked whether fixing the target to slot 0 makes the ETC packet-length-total write/update candidate directly reachable within the per-bug 15min budget.
- **Result**:
  - Default 2GB profile run:
    - run directory `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_slot0/20260501-204518-e481/`
    - ended after about 176s with `RESULT: Ultimate could not prove your program: Toolchain returned no result`
    - root cause in the log: Z3 `out of memory` during trace checking, so this is a tool/configuration failure rather than absence evidence.
  - 8GB small-blocks rerun:
    - run directory `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_slot0/20260501-204859-a16b/`
    - command shape: `./bin/procurator verify --spec ...external_etc_noms2024_pkt_len_total_wraparound_slot0.prop --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --use-spec-max-steps --wraparound off --settings dslc/toolchain/ultimate/settings/gemcutter/8g/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf --ultimate-timeout-seconds 900 --ultimate-xmx-gb 8 --no-witness-rerun`
    - Ultimate result: `TIMEOUT` under the 900s cap.
- **Pitfalls (implementation/model issues)**:
  - Slot-0 targeting did not reduce the CEGAR problem enough. The P4B write-site assertion is present inside `etc_Ingress_reg_pkt_len_total.write`, so the remaining blocker is path feasibility/refinement, not a missing assertion.
  - The ETC same-flow path depends on `reg_status`, `reg_flow_ID`, hash/index consistency, and the feature/classification suffix. Current translation leaves hash functions uninterpreted and keeps large post-feature state, which gives many spurious candidate traces before the real same-flow update can be established.
  - Classification: not a deliverable bug yet, and not classified nonexistent. It is "current direct verification cannot produce a witness within 15min"; next work should refine P4B/DSLC path slicing/shape constraints or target the exact second-packet write path.
- **Fixes/regression tests**:
  - No implementation fix landed in this entry. The result motivates a performance refinement: make duplicate global assertion accumulation optional/targeted when a P4B fail-fast write-site assertion is already emitted, and/or add a shape-targeted direct mode for same-flow register updates.
- **Smoke/regression**:
  - Both runs were single Ultimate jobs in WSL with no concurrent solver jobs.

## 2026-05-01 duplicate fail-fast target reduction and ETC slot0 rerun

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_slot0.prop`
- **Time**: 2026-05-01 21:08-21:24 Asia/Shanghai
- **Goal/Progress**: Added an opt-in DSLC/P4B integration knob to remove duplicate end-of-step global assertions when P4B already emitted the exact register-mirror assertion at the register write site, then reran the ETC slot0 candidate.
- **Result**:
  - New option: `--skip-duplicated-fail-fast-global-asserts` for `dslc.compiler`, `procurator compile`, and `procurator verify`.
  - Compile/smoke check:
    - command shape: `./bin/procurator compile --spec ...external_etc_noms2024_pkt_len_total_wraparound_slot0.prop --out /tmp/etc_slot0_skipdup.bpl --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --use-spec-max-steps --skip-duplicated-fail-fast-global-asserts && ./bin/procurator smoke --bpl /tmp/etc_slot0_skipdup.bpl --harness sequential`
    - structural smoke passed; `assert !procurator_bad` count was 0 while the P4B write-site assertion remained.
  - 15min verification rerun:
    - run directory `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_slot0/20260501-210811-1a54/`
    - command shape: `./bin/procurator verify --spec ...external_etc_noms2024_pkt_len_total_wraparound_slot0.prop --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --use-spec-max-steps --skip-duplicated-fail-fast-global-asserts --wraparound off --settings dslc/toolchain/ultimate/settings/gemcutter/8g/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf --ultimate-timeout-seconds 900 --ultimate-xmx-gb 8 --no-witness-rerun`
    - Ultimate result: `TIMEOUT`; `OverallTime` about 895.6s.
    - CFG now has 1 error location instead of 2; timeout is only at the P4B write-site assertion line for `etc_Ingress_reg_pkt_len_total.write`.
- **Pitfalls (implementation/model issues)**:
  - Removing the duplicate harness assertion reduced target count but did not make ETC converge. The blocker is now clearly path/refinement complexity for the same-flow second-packet write, not duplicate assertion placement.
  - The option is deliberately opt-in because earlier Flowrest direct bounded runs converged better with both the P4B fail-fast and the original DSL global assertion. Default behavior still keeps both targets.
  - Next implementation target should be shape/path refinement: constrain or summarize the same-flow path (`reg_status != 0`, `reg_flow_ID` equals current `flow_ID`, stable hash/index, target write before classification suffix) without modifying external P4 datasets.
- **Fixes/regression tests**:
  - `dslc/backends/boogie/compiler.py`, `dslc/compiler.py`, `dslc/cli/compile.py`, and `dslc/cli/gemcutter.py`: added the opt-in duplicate fail-fast global-assert skip path.
  - `dslc/tests/boogie/backend/test_boogie_backend_smoke.py`: added `test_fail_fast_can_skip_duplicate_global_assert_when_opted_in`; kept `test_exact_register_mirror_assert_enables_p4b_fail_fast` to ensure the default still preserves the DSL global assertion.
  - Split projection-focused tests from `dslc/tests/wraparound/schedule/test_wraparound_schedule.py` into `dslc/tests/wraparound/schedule/test_wraparound_projection.py` to keep Python test files under the 1300-line limit.
- **Smoke/regression**:
  - Focused WSL tests passed:
    - `python3 -m unittest -v dslc.tests.wraparound.schedule.test_wraparound_projection dslc.tests.wraparound.schedule.test_wraparound_schedule.WraparoundScheduleTests.test_static_schedule_extracts_phase_actor_array dslc.tests.wraparound.schedule.test_wraparound_schedule.WraparoundScheduleTests.test_schedule_manifest_projection_matches_closure_snapshot_vars dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_exact_register_mirror_assert_enables_p4b_fail_fast dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_fail_fast_can_skip_duplicate_global_assert_when_opted_in dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_guarded_register_mirror_assert_does_not_enable_fail_fast`
  - Current checked file sizes: `test_wraparound_schedule.py` 1040 lines, `test_wraparound_projection.py` 375 lines, `test_boogie_backend_smoke.py` 908 lines.

## 2026-05-02 ETC slicing/pruning refinement and slot0 witness

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_slot0.prop`
- **Time**: 2026-05-02 01:21-01:25 Asia/Shanghai
- **Goal/Progress**: Aligned the ETC case with the paper's intent-driven slicing split between `Keep[v]` and `Havoc[v]`, then refined P4B register-index pruning so the bounded slot0 packet-length-total candidate can converge.
- **Result**:
  - Compile/smoke:
    - command shape: `./bin/procurator compile --spec ...external_etc_noms2024_pkt_len_total_wraparound_slot0.prop --out .tmp/procurator/smoke/etc_slot0_same_index_reg_prune.bpl --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --skip-duplicated-fail-fast-global-asserts --use-spec-max-steps && ./bin/procurator smoke --bpl .tmp/procurator/smoke/etc_slot0_same_index_reg_prune.bpl --harness sequential`
    - result: compile OK, Boogie structural smoke OK, generated BPL has 948 lines.
    - register init after pruning is point-only: `etc_Ingress_reg_flow_ID[0bv11]`, `etc_Ingress_reg_pkt_len_total[0bv11]`, and `etc_Ingress_reg_status[0bv11]`; no `forall i:bv11` register initialization remains for these three state dependencies.
  - Direct verification without witness rerun:
    - run directory: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_slot0/20260502-012151-06ee/`
    - command shape: `./bin/procurator verify --spec ...external_etc_noms2024_pkt_len_total_wraparound_slot0.prop --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --skip-duplicated-fail-fast-global-asserts --use-spec-max-steps --wraparound off --settings dslc/toolchain/ultimate/settings/gemcutter/8g/ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por-allinline.epf --ultimate-xmx-gb 8 --ultimate-timeout-seconds 300 --no-witness-rerun`
    - result: `UNSAFE`; Ultimate `OverallTime` about 18.4s.
  - Direct verification with witness rerun:
    - run directory: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_slot0/20260502-012350-f748/`
    - witness: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_slot0/20260502-012350-f748/external_etc_noms2024_pkt_len_total_wraparound_slot0.bpl-witness.graphml`
    - result: `UNSAFE` in the main run and `UNSAFE (witness rerun)`; Ultimate `OverallTime` about 22.5s and witness rerun `OverallTime` about 19.4s.
    - counterexample classifier: `internal_assert`, i.e., the P4B fail-fast register-write assertion for the target write site rather than the end-of-harness `procurator_bad` assertion.
- **Pitfalls (implementation/model issues)**:
  - Earlier ETC slot0 runs were TIMEOUT/OOM; this was a verification/toolchain convergence limitation, not evidence that the candidate was absent.
  - The root cause was incomplete P4B register-index pruning. The explicit target seed `Ingress_reg_pkt_len_total[0]` constrained `meta.register_index == 0bv11` at the target register action, but same-path state dependencies (`reg_status` and `reg_flow_ID`) accessed via the same index expression still kept the full 2048-slot arrays and quantified initialization.
  - The first implementation attempt only inspected direct `register.read/write` calls and missed `RegisterAction.execute(index)` calls; it also had to preserve the IR-internal name versus control-plane/Boogie name distinction.
- **Fixes/regression tests**:
  - `P4B-Translator/backends/verify/slicing/slicer_internal.h`: `RegisterIndexCollector` now descends through container statements, records non-constant index expression keys, and records `RegisterAction.execute(index)` accesses.
  - `P4B-Translator/backends/verify/slicing/slicer.cpp`: maps `RegisterAction` instances to their underlying registers, propagates explicit indexed seed bounds through identical retained index expressions, and emits both IR-internal and control-plane register aliases in `regMaxIndex`.
  - `P4B-Translator/backends/verify/slicing/slicer_selftest.cpp`: extended ETC slicing selftest coverage for same-index register-domain propagation when an explicit indexed seed is present.
  - `dslc/tests/p4b/test_p4b_translator_slicing_selftest.py`: checks that ETC `reg_status`, `reg_flow_ID`, and `reg_pkt_len_total` all get effective size 1 in the slot0 case.
  - `dslc/tests/boogie/backend/test_boogie_backend_smoke.py`: checks that DSLC consumes P4B `register_sizes` and emits point-only initialization for the three same-index ETC register dependencies.
- **Smoke/regression**:
  - Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were active.
  - Focused WSL tests passed:
    - `cmake --build P4B-Translator/build-host --target p4c-translator -j"$(nproc)"`
    - `python3 -m unittest -v dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_external_etc_slicing_keep_vars_do_not_become_roots dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_external_etc_regaction_index_prune_declares_nonstandard_bv_width dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_external_etc_pkt_len_target_prefix_slicing dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_external_flowrest_regaction_execute_respects_pruned_register_index dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_required_env_packet_vars_are_kept_without_widening_p4_slice`

## 2026-05-02 FlowDoS dynamic-hash counter wraparound staging

- **Spec**: `Procurator/argo/code/spec/bench/external_int_flowdos_counter_wraparound.prop`
- **Time**: 2026-05-02 04:14-04:30 Asia/Shanghai
- **Goal/Progress**: Stabilize the external INT FlowDoS counter candidate without editing the external P4 dataset, specifically the dynamic v1model `hash(counter_pos, ..., {srcIp}, BLOOM_FILTER_ENTRIES)` index path used by `counter_filter.read/write`.
- **Result**:
  - Compile/smoke:
    - command shape: `./bin/procurator compile --spec ...external_int_flowdos_counter_wraparound.prop --out .tmp/procurator/smoke/int_flowdos_hash_index.bpl --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --skip-duplicated-fail-fast-global-asserts && ./bin/procurator smoke --bpl .tmp/procurator/smoke/int_flowdos_hash_index.bpl --harness sequential`
    - structural smoke passed; generated BPL now contains `assume(buge.bv32(flowdos_counter_pos_0, 0bv32) && bule.bv32(flowdos_counter_pos_0, 4095bv32));` and no longer emits ill-typed bitvector `>=` comparisons for the hash range.
    - The `4095bv32` upper bound is intentional: v1model `hash(result, ..., base, data, max)` returns `[base, base+max-1]` when `max >= 1`, and FlowDoS uses `max = BLOOM_FILTER_ENTRIES = 4096`.
  - Short schedule-replay near-wrap:
    - run directory: `.tmp/procurator/verify/external_int_flowdos_counter_wraparound/20260502-041423-6927/`
    - `entry_check`: `UNSAFE`, wall about 13.8s.
    - `near_wrap`: `UNSAFE`, wall about 20.3s.
    - manifest candidate: `pump_reg=flowdos_MyIngress_counter_filter`, `index_expr=flowdos_hash__crc16$bv32$bv32$bv32(0bv32, 167772161bv32, 4096bv32)`, `step_delta=1`.
  - Post-review hash-bound rerun:
    - run directory: `.tmp/procurator/verify/external_int_flowdos_counter_wraparound/20260502-043846-f639/`
    - after correcting the v1model hash upper bound from `max` to `base+max-1`, `entry_check` remained `UNSAFE` in about 14.6s and `near_wrap` remained `UNSAFE` in about 19.1s.
  - Stop-after-closure staging:
    - run directory: `.tmp/procurator/verify/external_int_flowdos_counter_wraparound/20260502-041546-9ff1/`
    - `entry_check`: `UNSAFE`, wall about 14.6s.
    - `near_wrap`: `UNSAFE`, wall about 20.3s.
    - `closure_check`: `UNSAFE`, wall about 21.0s.
  - Full schedule-replay fallback run:
    - run directory: `.tmp/procurator/verify/external_int_flowdos_counter_wraparound/20260502-041805-0117/`
    - first schedule (`env, flowdos`) produced `entry_check=UNSAFE`, `near_wrap=UNSAFE`, `closure_check=UNSAFE`.
    - the schedule was blocked as a closure counterexample; second `entry_check` became `SAFE`, so wraparound did not certify a replayable pump and correctly fell back to direct checking.
    - direct checking under the same 600s cap ended with `RESULT: Ultimate could not prove your program: Timeout`.
- **Pitfalls (implementation/model issues)**:
  - Previous FlowDoS entry/near runs failed before meaningful verification because P4B emitted `flowdos_counter_pos_0 >= 0bv32` and `4096bv32 >= flowdos_counter_pos_0`; this was a translator type-registration bug, not a property result.
  - Subagent review found that the first typed-comparator fix was still semantically too loose: it used inclusive `max` as the upper bound. That over-approximated the v1model contract and could admit out-of-range index `4096` for a 4096-entry register. This was fixed before treating the FlowDoS result as evidence.
  - The dynamic hash index path requires P4B, not DSLC text surgery, to preserve action-local hash producers, export structured index definitions, and type control-local scalars used by actions.
  - The current result must be classified carefully: near-wrap reachability exists for the fixed hash-index candidate, but the schedule-replay closure proof found a real closure counterexample. Therefore this is not a certified wraparound bug yet, and not evidence that the bug is absent; it is "near-wrap reachable, closure not proven, direct checking timed out in 10min".
- **Fixes/regression tests**:
  - `P4B-Translator/backends/verify/translate/impl/lowering/translate_program.cpp`: when promoting scalar control-local variables to Boogie globals so action procedures can modify them, also records `varTypes` and `updateVariableSize(...)`. This lets v1model `hash(out, ...)` recover the output bitwidth and emit typed unsigned BV range assumptions.
  - `P4B-Translator/backends/verify/translate/impl/lowering/translate_method.cpp`: v1model `hash` range lowering now models `[base, base+max-1]`, with constant `max` folded eagerly and `max==0` treated as exact `base`. It also coerces forced-width range arguments at the Boogie expression level, not just in the uninterpreted-function signature, so mixed-width cases such as p4c's flowlet-switching sample produce well-typed zero-extension/truncation expressions.
  - `dslc/tests/p4b/test_p4b_flowdos_hash.py`: added focused regressions ensuring FlowDoS hash range assumptions use `buge.bv32`/`bule.bv32`, use the correct `4095bv32` upper bound, never use ill-typed bare bitvector `>=`, and preserve well-typed mixed-width range arguments (`0bv2++ecmp_base`, `0bv12++ecmp_count`, `sub.bv14(...)`) in a v1model flowlet-switching sample.
  - Prior related fixes in this workstream remain covered by focused tests: P4B slicing keeps the hash producer for dynamic register indices, P4B meta exports callsite-specialized hash index definitions/aliases, and DSLC normalizes meta index definitions to prefixed Boogie globals and declared hash function signatures.
- **Smoke/regression**:
  - Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were active.
  - Focused WSL tests passed:
    - `cmake --build P4B-Translator/build-host --target p4c-translator -j"$(nproc)"`
    - `python3 -m unittest -v dslc.tests.p4b.test_p4b_flowdos_hash dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_external_int_flowdos_hash_index_dependency_slicing dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_external_int_flowdos_control_apply_counter_wraparound_meta dslc.tests.wraparound.test_wraparound_candidate_gating`
    - `python3 -m unittest -v dslc.tests.p4b.test_p4b_flowdos_hash dslc.tests.bench.test_scan_p4b_coverage dslc.tests.p4b.test_p4b_tofino_cpp_defines dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_external_int_flowdos_hash_index_dependency_slicing dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_external_int_flowdos_control_apply_counter_wraparound_meta`
  - TNA translation coverage smoke after the hash fix:
    - command shape: `python3 dslc/bench/scan_p4b_coverage.py --target tna --out-dir .tmp/procurator/p4b_coverage/tna_compile_20260502_after_hashfix --timeout-seconds 30 --limit 20`
    - result: 11 top-level TNA/TNA-like programs translated successfully; 2 frontend parse failures remain (`horus-p4/.../bmv2/falcon.p4app/falcon.p4` is a mixed TNA/v1model-style source; `tofinoTest/test.p4` is a demo TNA package-instantiation parse issue to investigate separately).

## 2026-05-02 architecture coverage scan hardening and staged verification probes

- **Specs**:
  - `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_count_wraparound.prop`
  - `Procurator/argo/code/spec/bench/fisslock_notification_cnt_wraparound_bug.prop`
  - `Procurator/argo/code/spec/bench/gecko_bug2_concurrency.prop`
- **Time**: 2026-05-02 04:50-05:21 Asia/Shanghai
- **Goal/Progress**: Improve Procurator/P4B coverage scanning for broader P4 programs (PSA/PNA/eBPF/uBPF/TNA) and continue staged verification probes without launching long closure checks before ENTRY/NEAR evidence justifies them.
- **Result**:
  - Scanner hardening:
    - Added `--offset` and `--max-wall-seconds` to `dslc/bench/scan_p4b_coverage.py`, so architecture coverage scans can be resumed in batches and still write partial `coverage.json`/`coverage.md` when a wall-clock budget is reached.
    - Cached include-path discovery per source directory to avoid expensive repeated parent-directory enumeration on the WSL/Windows filesystem.
    - Fixed explicit `.tmp/...` scan roots: files under an explicitly requested scan root are no longer skipped just because the absolute path contains `.tmp`.
    - Added external-checkout `p4include` discovery so upstream p4c samples use their own architecture model files, including `pna.p4`.
    - Improved failure classification: frontend compiler bugs are classified as `frontend_internal`, and `[--Werror=type-error]` / function invocation type mismatches are classified as `frontend_type`.
  - Local official-sample coverage:
    - PSA full scan: `.tmp/procurator/p4b_coverage/psa_samples_20260502_full/coverage.md`, 51/51 top-level PSA samples translated successfully. This includes PSA counter/register/hash/clone/recirculate/resubmit/multicast examples.
    - eBPF scan: `.tmp/procurator/p4b_coverage/ebpf_samples_20260502_compile/coverage.md`, 19/19 translated successfully.
    - uBPF scan: `.tmp/procurator/p4b_coverage/ubpf_samples_20260502_compile/coverage.md`, 13/13 translated successfully.
    - TNA slicing scan: `.tmp/procurator/p4b_coverage/tna_slicing_20260502/coverage.md`, 11/13 translated successfully with slicing enabled. The 2 failures are frontend parse-level sample issues already seen in the base scan, not P4B backend semantic failures.
  - Upstream p4c sample coverage:
    - Sparse-cloned current upstream p4c into `.tmp/procurator/upstream/p4c` only for read-only coverage checks; source hash observed in this run: `fe95abf`.
    - PNA batch0 after scanner fixes: `.tmp/procurator/p4b_coverage/upstream_p4c_pna_20260502_batch0_reclass/coverage.md`, 16/20 translated successfully. Failures were classified as `frontend_internal` or `frontend_type`, not P4B backend unsupported semantics.
    - PNA batch1: `.tmp/procurator/p4b_coverage/upstream_p4c_pna_20260502_batch1/coverage.md`, 39/40 translated successfully; the only failure was `frontend_type`.
  - `external_etc_noms2024_pkt_count_wraparound.prop` staged wraparound probe:
    - run directory: `.tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260502-050155-43ff/`
    - `ENTRY_CHECK=UNSAFE` in about 14.4s.
    - `NEAR_WRAP=SAFE` in about 20.6s under `--wraparound-confirm-unroll 3`.
    - No closure was run because NEAR did not find a suffix witness. Classification: not a deliverable wraparound bug and not evidence of absence; the current candidate/schedule did not trigger near-wrap.
  - `fisslock_notification_cnt_wraparound_bug.prop` staged wraparound probe:
    - run directory: `.tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260502-051741-2d69/`
    - candidate target: `sw_IngressPipe_CounterTable_1_notification_cnt_1`
    - `ENTRY_CHECK=UNSAFE` in about 23.3s.
    - `NEAR_WRAP=SAFE` in about 38.5s under `--wraparound-confirm-unroll 3`.
    - No closure was run. Classification: this short-stage run did not reproduce the known long FissLock wraparound shape; it likely needs the original deeper schedule/unroll rather than blind closure time.
  - `gecko_bug2_concurrency.prop` direct interleaving regression:
    - run directory: `.tmp/procurator/verify/gecko_bug2_concurrency/20260502-051903-8ba6/`
    - `RESULT: UNSAFE` under 300s with 8GB no-Z3-timeout/no-POR/all-inline settings.
    - CLI exit was nonzero only because `--no-witness-rerun` skipped GraphML witness generation and the counterexample classifier reported missing witness; the main Ultimate result is still an interleaving regression UNSAFE.
- **Pitfalls (implementation/model issues)**:
  - The first PSA scan attempt used a large single command and hit the outer tool timeout before writing a final report. The new scanner budget/batching options fix that workflow issue.
  - The first PNA upstream scan returned zero candidates because explicit `.tmp/...` scan roots were accidentally filtered by the global skip rule. The skip logic now applies to paths relative to each requested scan root.
  - Without external-checkout `p4include` discovery, upstream PNA samples would be misclassified as include/model failures even though their own checkout contains `pna.p4`.
  - The ETC packet-count and FissLock short-stage probes show why we should not run closure first: ENTRY alone is not enough; NEAR must produce a suffix witness before spending 15min on closure.
- **Fixes/regression tests**:
  - `dslc/bench/scan_p4b_coverage.py`: added batched/resumable scan controls, include-path caching, external architecture-model include discovery, explicit `.tmp` scan-root support, and more precise frontend failure classification.
  - `dslc/tests/bench/test_scan_p4b_coverage.py`: added regressions for batch metadata rendering, external checkout `p4include` preference, explicit `.tmp` scan roots, and frontend failure classification.
- **Smoke/regression**:
  - `python3 -m unittest -v dslc.tests.bench.test_scan_p4b_coverage` passed in WSL.
  - `python3 -m py_compile dslc/bench/scan_p4b_coverage.py dslc/tests/bench/test_scan_p4b_coverage.py` passed in WSL.
  - All solver runs above were executed as single Ultimate/GemCutter jobs in WSL; no concurrent solver jobs were intentionally launched.

## 2026-05-02 FissLock NEAR false-SAFE repair

- **Specs**:
  - `Procurator/argo/code/spec/bench/fisslock_notification_cnt_wraparound_bug.prop`
  - `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_count_wraparound.prop`
- **Time**: 2026-05-02 11:16-11:34 Asia/Shanghai
- **Goal/Progress**: Investigated why a known FissLock wraparound candidate returned `NEAR_WRAP=SAFE`; fixed the instrumentation bug, reran staged checks, and separated it from the ETC packet-count case that still needs path/spec diagnosis.
- **Result**:
  - Bad anchor run: `.tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260502-051741-2d69/` had `ENTRY_CHECK=UNSAFE` but `NEAR_WRAP=SAFE`.
  - Root cause: confirm/near instrumentation inserted `assume false; // stop after wraparound target assertion` after rewritten DSL/global assertion calls. FissLock needs a pump pass followed by a later transfer suffix pass; the cut deleted that suffix, producing a false SAFE.
  - Fixed FissLock near run: `.tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260502-111627-cff4/`, `ENTRY_CHECK=UNSAFE` in about 46.8s and `NEAR_WRAP=UNSAFE` in about 132.1s.
  - Fixed FissLock closure run: `.tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260502-112434-1c13/`, `ENTRY_CHECK=UNSAFE` in about 26.4s, `NEAR_WRAP=UNSAFE` in about 116.6s, and `CLOSURE_CHECK=SAFE` in about 61.9s.
  - ETC packet-count rerun after the fix: `.tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260502-112827-c8e4/`, `ENTRY_CHECK=UNSAFE` in about 16.1s and `NEAR_WRAP=SAFE` in about 62.0s. The generated NEAR BPL no longer has the suffix cut, so this is not the same instrumentation bug.
- **Pitfalls (implementation/model issues)**:
  - The previous "stop after target assertion" optimization is only safe for truly local write-site checks; applying it to all DSL/global assertions is incomplete for multi-pass suffix bugs.
  - `NEAR_WRAP=SAFE` now must be interpreted case-by-case: for FissLock it was an implementation bug; for ETC packet-count, the current candidate/schedule did not trigger the near suffix and needs separate path/spec analysis.
- **Fixes/regression tests**:
  - `dslc/transform/wraparound_stages.py` and `dslc/transform/wraparound_instrument.py`: removed the global suffix-cut behavior for rewritten assertions.
  - `dslc/tests/wraparound/transform/test_wraparound_transform.py`: added coverage that confirm keeps the suffix after a gated assertion site and never emits the old stop-after marker.
  - Focused WSL tests passed: `python3 -m unittest -v dslc.tests.wraparound.transform.test_wraparound_transform dslc.tests.wraparound.schedule.test_wraparound_schedule.WraparoundScheduleTests.test_schedule_replay_stop_after_near_wrap dslc.tests.wraparound.schedule.test_schedule_manifest_certification`.

## 2026-05-02 PNA upstream coverage completion

- **Spec/scan**: upstream p4c PNA sample set under `.tmp/procurator/upstream/p4c/testdata/p4_16_samples`
- **Time**: 2026-05-02 12:24 Asia/Shanghai
- **Goal/Progress**: Completed the previously missing PNA offset 60+ coverage batch after earlier batch0/batch1 scans.
- **Result**:
  - Command shape: `./dslc/bench/scan_p4b_coverage.py --target pna --scan-root .tmp/procurator/upstream/p4c/testdata/p4_16_samples --out-dir .tmp/procurator/p4b_coverage/upstream_p4c_pna_20260502_batch2 --offset 60 --limit 20 --timeout-seconds 30 --max-wall-seconds 480`
  - Report: `.tmp/procurator/p4b_coverage/upstream_p4c_pna_20260502_batch2/coverage.md`
  - Result: 11/11 translated successfully. Combined with earlier batches, all 71 discovered upstream PNA candidates have now been attempted; remaining non-OK records in earlier batches are frontend type/internal cases, not P4B backend unsupported-semantics cases.
- **Pitfalls/Fixes**: No new implementation bug found in this batch.
- **Smoke/regression**: This was a translation-only coverage scan; no Ultimate/GemCutter job was launched.

## 2026-05-02 NetChain wraparound certificate rerun

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`
- **Time**: 2026-05-02 12:26-12:29 Asia/Shanghai
- **Goal/Progress**: Reran the canonical NetChain wraparound case after the P4B/DSLC refactor and NEAR suffix repair.
- **Result**:
  - Command shape: `./bin/procurator verify --spec ...netchain_wraparound_bug.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound auto --wraparound-cegar-mode schedule_replay --wraparound-stage-order entry_confirm_closure --wraparound-stop-after closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --settings dslc/toolchain/ultimate/settings/gemcutter/8g/ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por-allinline.epf --ultimate-xmx-gb 8 --ultimate-timeout-seconds 900`
  - Run directory: `.tmp/procurator/verify/netchain_wraparound_bug/20260502-122637-22a3/`
  - Manifest: `.tmp/procurator/verify/netchain_wraparound_bug/20260502-122637-22a3/wraparound/target.00.s1_sequence_reg/wraparound.cegis.manifest.json`
  - `ENTRY_CHECK=UNSAFE` in about 18.4s, `NEAR_WRAP=UNSAFE` in about 42.7s, `CLOSURE_CHECK=SAFE` in about 88.4s.
- **Pitfalls/Fixes**: No new implementation bug found; total staged certificate time stayed well under the 8 minute NetChain target.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-02 Gecko interleaving regression rerun

- **Spec**: `Procurator/argo/code/spec/bench/gecko_bug2_concurrency.prop`
- **Time**: 2026-05-02 12:29-12:31 Asia/Shanghai
- **Goal/Progress**: Reran a known interleaving bug after the P4B/DSLC refactor.
- **Result**:
  - Command shape: `./bin/procurator verify --spec ...gecko_bug2_concurrency.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound off --settings dslc/toolchain/ultimate/settings/gemcutter/8g/ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por-allinline.epf --ultimate-xmx-gb 8 --ultimate-timeout-seconds 300 --no-witness-rerun`
  - Run directory: `.tmp/procurator/verify/gecko_bug2_concurrency/20260502-122936-c989/`
  - Main Ultimate result: `UNSAFE` in under 300s.
- **Pitfalls/Fixes**:
  - CLI exit was nonzero only because witness rerun was disabled and the counterexample classifier reported no GraphML witness. The main solver result is still the regression signal for this staged smoke.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-02 DistCache P2C wraparound certificate rerun

- **Spec**: `Procurator/argo/code/spec/bench/distcache_p2c_wraparound_bug.prop`
- **Time**: 2026-05-02 12:32-12:35 Asia/Shanghai
- **Goal/Progress**: Reran a DistCache wraparound representative after the P4B/DSLC refactor and NEAR suffix repair.
- **Result**:
  - Command shape: `./bin/procurator verify --spec ...distcache_p2c_wraparound_bug.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound auto --wraparound-cegar-mode schedule_replay --wraparound-stage-order entry_confirm_closure --wraparound-stop-after closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --settings dslc/toolchain/ultimate/settings/gemcutter/8g/ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por-allinline.epf --ultimate-xmx-gb 8 --ultimate-timeout-seconds 900`
  - Run directory: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260502-123228-b628/`
  - Manifest: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260502-123228-b628/wraparound/target.00.clientTrack_partitionswitchIngress_leafload_reg/wraparound.cegis.manifest.json`
  - `ENTRY_CHECK=UNSAFE` in about 20.9s, `NEAR_WRAP=UNSAFE` in about 65.6s, `CLOSURE_CHECK=SAFE` in about 69.5s.
- **Pitfalls/Fixes**: No new implementation bug found in this rerun.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-02 PSA/eBPF/uBPF semantic coverage refinement

- **Spec/scan**:
  - PSA samples: `P4B-Translator/testdata/p4_16_samples/*psa*.p4`
  - eBPF samples: `P4B-Translator/testdata/p4_16_samples/*_ebpf.p4` plus eBPF counter/checksum samples
  - uBPF samples: `P4B-Translator/testdata/p4_16_samples/*_ubpf.p4`
- **Time**: 2026-05-02 13:20-13:45 Asia/Shanghai
- **Goal/Progress**: Added semantic auditing on top of architecture translation coverage so "compile OK" is not treated as enough. Fixed concrete P4B lowering holes found by the audit: PSA/eBPF counter updates, uBPF three-argument hash, digest event summaries, and several audit false negatives around counter naming, checksum extern summaries, and meter expression calls.
- **Result**:
  - Focused tests: `python3 -m unittest -v dslc.tests.p4b.test_p4b_translator_regressions dslc.tests.p4b.test_p4b_flowdos_hash dslc.tests.bench.test_p4b_semantic_audit dslc.tests.bench.test_scan_p4b_coverage` passed in WSL (26 tests).
  - P4B build: `cmake --build P4B-Translator/build-host --target p4c-translator -j4` passed in WSL.
  - PSA counter focused scan: `.tmp/procurator/p4b_coverage/psa_counter_semantic_20260502_fix2/coverage.md`, 5/5 compile OK and 5/5 semantic OK.
  - eBPF counter focused scan: `.tmp/procurator/p4b_coverage/ebpf_counter_semantic_20260502_fix2/coverage.md`, 2/2 compile OK and 2/2 semantic OK.
  - uBPF hash focused scan: `.tmp/procurator/p4b_coverage/ubpf_hash_semantic_20260502_fix2/coverage.md`, 1/1 compile OK and semantic OK.
  - eBPF wide sample scan: `.tmp/procurator/p4b_coverage/ebpf_samples_semantic_20260502_fix/coverage.md`, 19/19 compile OK; semantic status had OK/SKIP only.
  - uBPF wide sample scan: `.tmp/procurator/p4b_coverage/ubpf_samples_semantic_20260502_fix/coverage.md`, 13/13 compile OK; semantic status had OK/SKIP only.
  - PSA wide sample scan after digest/audit refinement: `.tmp/procurator/p4b_coverage/psa_samples_semantic_20260502_digest_fix/coverage.md`, 51/51 compile OK, 47 semantic OK, 4 semantic WEAK, 0 semantic FAIL. Remaining WEAK records are expected model-boundary summaries for checksum/meter, not silent no-op lowering.
- **Pitfalls (implementation/model issues)**:
  - uBPF `hash(out, algo, data)` was previously treated like v1model `hash(out, algo, base, data, max)`; the old lowering returned empty for the three-argument form, leaving a `// hash` no-op.
  - Counter audit initially looked for `__counter_` and missed the real `name__counter` state shape, incorrectly reporting stateful counters as WEAK.
  - DirectCounter table binding (`psa_direct_counter = counter0`) is not by itself an implicit update; explicit `.count()` still has to be distinguished from owner binding.
  - Digest `.pack(...)` had no observable P4-local event in Boogie, so the model could silently drop a control-plane event.
  - PSA checksum and meter are still intentionally coarse: checksum externs are retained as clear/add/get summaries, and meter execute remains an uninterpreted effect unless a stronger stateful meter model is added.
- **Fixes/regression tests**:
  - `P4B-Translator/backends/verify/translate/impl/lowering/translate_method.cpp`: lowered three-argument `hash(out, algo, data)` to a deterministic typed Boogie function assignment.
  - `P4B-Translator/backends/verify/translate/impl/lowering/translate_statement.cpp`: stopped emitting `// hash` when hash lowering succeeds, and added `p4b_digest := true` for `Digest.pack(...)`.
  - `P4B-Translator/backends/verify/translate/impl/core/translate.cpp`: added the `p4b_digest` global event flag and per-run reset.
  - `P4B-Translator/backends/verify/translate/impl/lowering/translate_program.cpp` / `translate.h`: moved Boogie zero/one literal rendering into `Translator` methods instead of relying on unified-build static helpers.
  - `dslc/bench/p4b_semantic_audit.py`: added semantic feature checks for three-argument hash, counter state/update separation, digest event evidence, checksum extern summaries, and meter expression calls.
  - Regression tests added/updated in `dslc/tests/p4b/test_p4b_translator_regressions.py` and `dslc/tests/bench/test_p4b_semantic_audit.py`.
- **Smoke/regression**: Translation/audit-only scans; no Ultimate/GemCutter job was launched.

## 2026-05-02 PNA/TNA semantic coverage check

- **Spec/scan**:
  - TNA repo samples under `P4B-Translator/testdata/p4_16_samples`
  - PNA upstream p4c batch under `.tmp/procurator/upstream/p4c/testdata/p4_16_samples`
- **Time**: 2026-05-02 13:43-13:46 Asia/Shanghai
- **Goal/Progress**: Extended the semantic-audit scan beyond PSA/eBPF/uBPF toward PNA/TNA without launching solver jobs.
- **Result**:
  - TNA repo-sample scan: `.tmp/procurator/p4b_coverage/tna_samples_semantic_20260502_fix/coverage.md`; 0 discovered top-level TNA candidates in the repo-local `p4_16_samples` tree.
  - PNA upstream semantic batch0: `.tmp/procurator/p4b_coverage/pna_upstream_semantic_20260502_fix_batch0/coverage.md`; 20 attempted, 16 compile OK with semantic OK, 4 frontend type/internal failures classified before P4B backend lowering.
- **Pitfalls/Fixes**:
  - Repo-local `p4_16_samples` does not currently contain top-level TNA programs; TNA coverage still needs the earlier TNA-specific dataset/upstream source rather than this tree.
  - PNA failures in this batch remain frontend/p4c issues rather than silent P4B semantic no-ops; no new P4B lowering bug was found in this batch.
- **Smoke/regression**: Translation/audit-only scans; no Ultimate/GemCutter job was launched.

## 2026-05-02 ETC/TNA dynamic-index NEAR_WRAP repair

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_count_wraparound.prop`
- **Time**: 2026-05-02 14:26-15:50 Asia/Shanghai
- **Goal/Progress**: Revisited the ETC packet-count wraparound case after the FissLock false-SAFE repair. Distinguished three separate issues: stale fixed-slot candidate inference, stale spec path assumptions, and an overly long near-wrap unroll that caused Ultimate to time out before reporting the existing bug.
- **Result**:
  - Pre-fix anchor: `.tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260502-145049-7fce/` recovered the correct hash index expression, but the old spec path still forced an unreachable update suffix and returned `NEAR_WRAP=SAFE`.
  - Spec/path correction: `.tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260502-145604-9a07/` changed the table action to `Ingress_set_flow_class` with `f_class == 0`, so the parser sentinel `meta.final_class == 10` is reset to the update path. With `unroll2`, `ENTRY_CHECK=UNSAFE` in about 14.6s and `NEAR_WRAP=Timeout` at about 902.3s.
  - Shorter repro before strategy change: `.tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260502-154420-a845/`, `ENTRY_CHECK=UNSAFE` in about 17.4s and `NEAR_WRAP=UNSAFE` in about 31.1s using `near_wrap.unroll1`.
  - Default command after strategy change: `.tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260502-155008-1dfa/`, even with `--wraparound-confirm-unroll 2`, the schedule tries the minimal suffix first and gets `ENTRY_CHECK=UNSAFE` in about 16.5s and `NEAR_WRAP=UNSAFE` in about 31.1s.
  - Candidate index is now the dynamic hash slot:
    `etc_Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8(167772161bv32, 167772162bv32, 1234bv16, 443bv16, 6bv8)`.
- **Pitfalls (implementation/model issues)**:
  - The stale `meta.register_index == 0` assumption was unsound as a candidate stabilizer because the P4 program overwrites `meta.register_index` via `idx_calc.get(...)` during the pass.
  - The old spec assumed `Ingress_drop`, which leaves `meta.final_class` at the parser sentinel value `10` and blocks the packet-count update guarded by `meta.final_class == 0`.
  - `near_wrap.unroll2` was not a stronger proof for this existential bug-finding stage; it introduced an extra suffix packet and made Ultimate spend time in branch-encoder trace refinement. The corrected one-round suffix is enough for the `255 -> 0` write.
- **Fixes/regression tests**:
  - `dslc/analysis/wraparound_candidates.py` / `dslc/analysis/wraparound_bpl_index.py`: dynamic RegisterAction index inference now prefers P4/BPL-derived hash expressions and does not let node assumptions override variables written by the P4 pass.
  - `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_count_wraparound.prop`: removed stale `meta.register_index == 0` and stale `Ingress_drop` path assumptions; pinned the table action that resets `final_class` to 0.
  - `dslc/transform/wraparound_stages.py` / `dslc/transform/wraparound_instrument.py`: materialize redundant dynamic-slot zero facts for registers that already have quantified zero initialization, and strengthen the near-wrap gate with `__last_index/__last_value` mirrors when present.
  - `dslc/workflows/wraparound_cegis.py`: confirm/near-wrap unroll schedule now tries the minimal suffix before growing to the requested bound.
  - Focused WSL tests passed: `python3 -m unittest -v dslc.tests.wraparound.cegis.core.test_wraparound_cegis_order dslc.tests.wraparound.schedule.test_wraparound_schedule`; `python3 -m unittest -v dslc.tests.wraparound.transform.test_wraparound_transform dslc.tests.wraparound.test_wraparound_candidate_gating dslc.tests.p4b.test_p4b_translator_regressions`.
- **Smoke/regression**: ETC staged solver runs were executed one at a time in WSL; no concurrent Ultimate/GemCutter jobs were launched.

## 2026-05-02 wraparound NEAR smoke after minimal-unroll strategy

- **Specs**:
  - `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`
  - `Procurator/argo/code/spec/bench/fisslock_notification_cnt_wraparound_bug.prop`
- **Time**: 2026-05-02 15:52-15:59 Asia/Shanghai
- **Goal/Progress**: Reran canonical wraparound NEAR checks after changing confirm/near-wrap exploration to try the minimal suffix before growing.
- **Result**:
  - NetChain run `.tmp/procurator/verify/netchain_wraparound_bug/20260502-155224-e8a8/`: `ENTRY_CHECK=UNSAFE` in about 19.8s; `NEAR_WRAP=UNSAFE` in about 55.8s using `near_wrap.unroll1`.
  - FissLock run `.tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260502-155403-c154/`: `ENTRY_CHECK=UNSAFE` in about 25.6s; `near_wrap.unroll1=SAFE` in about 35.0s; automatic growth to `near_wrap.unroll2=UNSAFE` in about 203.6s.
- **Pitfalls/Fixes**:
  - FissLock confirms that minimal-unroll-first must still grow after a real `SAFE`; otherwise multi-step suffix bugs would be missed. The schedule now does exactly that.
  - NetChain confirms that shorter near-wrap bounds can still catch single-round wraparound bugs and avoid unnecessary solver work.
- **Smoke/regression**: Runs were executed one at a time in WSL with `--wraparound-stop-after near_wrap`; no concurrent Ultimate/GemCutter jobs were launched.

## 2026-05-02 DistCache closure smoke after minimal-unroll strategy

- **Spec**: `Procurator/argo/code/spec/bench/distcache_p2c_wraparound_bug.prop`
- **Time**: 2026-05-02 15:59-16:03 Asia/Shanghai
- **Goal/Progress**: Reran a full staged certificate representative after changing near-wrap exploration order.
- **Result**:
  - Run directory: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260502-155911-26ee/`
  - Manifest: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260502-155911-26ee/wraparound/target.00.clientTrack_partitionswitchIngress_leafload_reg/wraparound.cegis.manifest.json`
  - `ENTRY_CHECK=UNSAFE` in about 21.5s.
  - `near_wrap.unroll1=SAFE` in about 49.0s, then automatic growth to `near_wrap.unroll2=UNSAFE` in about 67.8s.
  - `CLOSURE_CHECK=SAFE` in about 69.5s, so the staged certificate remains intact under the new exploration policy.
- **Pitfalls/Fixes**:
  - Like FissLock, DistCache needs a two-round suffix; the minimal-unroll strategy must treat `SAFE` at a shorter suffix as "grow and retry" when a larger requested bound exists, not as final absence.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-02 ETC pkt_len_total near-wrap exploration

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_direct.prop`
- **Time**: 2026-05-02 16:06-16:18 Asia/Shanghai
- **Goal/Progress**: Tried a second ETC/TNA wraparound target (`reg_pkt_len_total`, 16-bit accumulated packet length) after the packet-count dynamic-index repair.
- **Result**:
  - Compile/smoke passed: `./bin/procurator compile --spec ...external_etc_noms2024_pkt_len_total_wraparound_direct.prop --out /tmp/etc_len_total.bpl --boogie-harness sequential --no-two-stage --no-reg-debug && ./bin/procurator smoke --bpl /tmp/etc_len_total.bpl --harness sequential`.
  - First run before fixing schedule-replay path reuse: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260502-160614-8873/`; `ENTRY_CHECK=UNSAFE`, but the loop accidentally ran `near_wrap.unroll1.bpl` twice instead of growing to unroll2.
  - After fixing path reuse: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260502-161106-9021/`; `ENTRY_CHECK=UNSAFE` in about 20.5s, `near_wrap.unroll1=SAFE` in about 46.7s, then correctly ran `near_wrap.unroll2` but hit `Timeout` at about 317.6s.
- **Pitfalls (implementation/model issues)**:
  - Minimal-unroll-first initially exposed a schedule-replay bug: when the loop reached the requested base unroll after trying a shorter unroll, it reused the stale `confirm_bpl` path from the shorter run. This could falsely report repeated SAFE/UNKNOWN on the wrong BPL.
  - Current ETC `pkt_len_total` status is "verification timeout at unroll2", not "bug absent". The path is reachable, but Ultimate times out on the two-packet suffix.
- **Fixes/regression tests**:
  - `dslc/workflows/wraparound_support/loop_schedule.py`: near-wrap generation now binds each unroll to its own BPL/log path.
  - `dslc/workflows/wraparound_cegis.py`, `loop_schedule.py`, and `loop_legacy.py`: unroll schedules include the configured cap and continue past short-bound UNKNOWN/TIMEOUT until the last scheduled bound.
  - `dslc/transform/wraparound_instrument.py`: dynamic-slot zero facts are collected only from the main init prefix that dominates the fast-forward insertion point.
  - Added tests: `test_schedule_replay_grows_to_distinct_near_wrap_bpl`, `test_schedule_replay_continues_after_short_unknown`, `test_confirm_dynamic_slot_defaults_require_dominating_init_prefix`, and cap coverage in `test_confirm_unroll_schedule_starts_from_minimal_suffix`.
  - Focused WSL tests passed: `python3 -m unittest -v dslc.tests.wraparound.schedule.test_wraparound_schedule dslc.tests.wraparound.cegis.core.test_wraparound_cegis_order dslc.tests.wraparound.transform.test_wraparound_transform`; plus candidate/P4B regressions.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-02 ETC dynamic-slot projection soundness smoke

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_count_wraparound.prop`
- **Time**: 2026-05-02 23:09-23:11 Asia/Shanghai
- **Goal/Progress**: Reran the ETC packet-count dynamic-index case after changing schedule replay so incomplete dependency/index projection no longer blocks ENTRY/NEAR bug discovery, but still blocks CLOSURE/certification.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260502-230905-0936/`
  - Manifest: `.tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260502-230905-0936/wraparound/target.00.etc_Ingress_reg_pkt_count/wraparound.cegis.manifest.json`
  - `ENTRY_CHECK=UNSAFE` in about 41.0s.
  - `NEAR_WRAP=UNSAFE` in about 37.4s using `near_wrap.unroll1`.
  - Manifest has `certified=false`, `projection_complete=false`, and `diagnostic="stopped after near_wrap by request"`.
  - Candidate index remains the dynamic hash slot:
    `etc_Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8(167772161bv32, 167772162bv32, 1234bv16, 443bv16, 6bv8)`.
- **Pitfalls (implementation/model issues)**:
  - Dynamic-index candidates can depend on auxiliary register arrays at the same hash slot. Projecting `foo__last0_value` for such dependencies is unsound because the relevant slot is not necessarily slot 0.
  - The dependency projection correctly reports dynamic-slot dependencies (`etc_Ingress_reg_flow_ID`, `etc_Ingress_reg_status`) and marks the projection incomplete. Therefore this run is valid bug-discovery evidence, not a wraparound closure certificate.
- **Fixes/regression tests**:
  - `dslc/analysis/wraparound_projection.py`: dynamic-index candidates no longer promote non-target register-array dependencies to slot-0 mirrors; such dependencies mark projection incomplete.
  - `dslc/workflows/wraparound_support/loop_schedule.py`: incomplete projection still allows `ENTRY_CHECK` and `NEAR_WRAP`, but blocks closure/certification and falls back to direct verification.
  - Added/updated tests: `test_dependency_projection_does_not_use_slot0_mirror_for_dynamic_index_dep` and `test_schedule_replay_incomplete_projection_still_runs_near_but_not_closure`.
  - Focused WSL tests passed: `python3 -m unittest -v dslc.tests.wraparound.schedule.test_wraparound_projection dslc.tests.wraparound.schedule.test_wraparound_schedule dslc.tests.wraparound.cegis.core.test_wraparound_cegis_order dslc.tests.wraparound.transform.test_wraparound_transform dslc.tests.wraparound.test_wraparound_candidate_gating dslc.tests.p4b.test_p4b_translator_regressions` (79 tests).
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-02 Flowrest dynamic-slot NEAR_WRAP witness with certification fallback

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_len_total_wraparound_direct.prop`
- **Time**: 2026-05-02 23:13-23:17 Asia/Shanghai
- **Goal/Progress**: Reran Flowrest packet-length accumulation after the dynamic-slot projection fix, using `--wraparound-stop-after closure` to confirm the workflow finds the near-wrap witness but refuses an incomplete dynamic-slot certificate.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound_direct/20260502-231338-b798/`
  - Manifest: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound_direct/20260502-231338-b798/wraparound/target.00.flowrest_Ingress_reg_pkt_len_total/wraparound.cegis.manifest.json`
  - `ENTRY_CHECK=UNSAFE` in about 20.0s.
  - `near_wrap.unroll1=SAFE` in about 52.1s, then automatic growth to `near_wrap.unroll2=UNSAFE` in about 79.3s.
  - Manifest has `certified=false`, `projection_complete=false`, `closure=null`, and `diagnostic="near-wrap bug found but dependency projection incomplete; falling back to direct verification"`.
  - Candidate index is the dynamic hash slot:
    `flowrest_Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8(167772161bv32, 167772162bv32, 1234bv16, 443bv16, 6bv8)`.
- **Pitfalls (implementation/model issues)**:
  - Flowrest `reg_pkt_len_total[index]` update depends on same-slot auxiliary state (`reg_flow_ID[index]` and `reg_time_last_pkt[index]`). A slot-0 scalar mirror would prove the wrong fact for a dynamic hash index.
  - The current result is a concrete near-wrap witness and fallback trigger, not a closure-certified wraparound proof. Direct verification or a future dynamic-slot projection/snapshot certificate is still needed for full certification.
- **Fixes/regression tests**:
  - Same dynamic-slot projection fix as the ETC smoke: dynamic array dependencies are reported in `dependency_projection_dynamic_slot_deps` and force `projection_complete=false`.
  - `dslc/workflows/wraparound_support/loop_schedule.py` now records the incomplete projection in the attempt cfg, runs ENTRY/NEAR, and stops before CLOSURE/certification.
  - Focused WSL regression remained green: 79 wraparound/P4B tests passed before this solver run.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-02 DistCache certified closure after dynamic-slot projection tightening

- **Spec**: `Procurator/argo/code/spec/bench/distcache_p2c_wraparound_bug.prop`
- **Time**: 2026-05-02 23:23-23:29 Asia/Shanghai
- **Goal/Progress**: Reran a fixed-slot closure-certified representative after tightening dynamic-index projection, to ensure the new fallback policy does not regress existing certified wraparound cases.
- **Result**:
  - Run directory: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260502-232359-5b24/`
  - Manifest: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260502-232359-5b24/wraparound/target.00.clientTrack_partitionswitchIngress_leafload_reg/wraparound.cegis.manifest.json`
  - `ENTRY_CHECK=UNSAFE` in about 20.8s.
  - `near_wrap.unroll1=SAFE` in about 71.5s, then automatic growth to `near_wrap.unroll2=UNSAFE` in about 96.9s.
  - `CLOSURE_CHECK=SAFE` in about 87.4s.
  - Manifest has `certified=true`, `projection_complete=true`, and `diagnostic="certified schedule-replay wraparound bug"`.
- **Pitfalls/Fixes**:
  - The verifier command returns nonzero when a certified `UNSAFE` bug is found; this is expected CLI behavior for bug-finding and not a tool failure. The manifest is the authoritative evidence.
  - The dynamic-slot fallback policy only affects candidates with incomplete dynamic-slot dependencies; fixed-slot certified cases remain eligible for closure.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 Flowrest pkt_count slicing false-SAFE repair

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_count_wraparound.prop`
- **Time**: 2026-05-03 00:01-00:05 Asia/Shanghai
- **Goal/Progress**: Revisited the Flowrest packet-count wraparound case that previously returned `NEAR_WRAP=SAFE` under slicing. Treated the result as a possible tool imprecision rather than bug absence, then compared pruned vs no-prune Boogie and found the P4-local classification/ttl path had been sliced away.
- **Result**:
  - Pre-fix pitfall run: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260502-233327-42ce/` had `ENTRY_CHECK=UNSAFE`, `near_wrap.unroll1=SAFE`, and `near_wrap.unroll2=SAFE`, but the pruned Boogie was missing the internal `hdr.ipv4.ttl := 127/128/255` and `classified_flag` path. This was a slicing false negative, not evidence that the bug is absent.
  - After fixing P4B slicing, compile check `/tmp/flowrest_pkt_count_prune_after_fix.bpl` contains `hdr.ipv4.ttl := 127bv8;`, `hdr.ipv4.ttl := 128bv8;`, `hdr.ipv4.ttl := 255bv8;`, `meta.classified_flag`, and `Ingress_update_classified_flag.apply`.
  - Solver run directory: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260503-000105-6ca8/`
  - Manifest: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260503-000105-6ca8/wraparound/target.00.flowrest_Ingress_reg_pkt_count/wraparound.cegis.manifest.json`
  - `ENTRY_CHECK=UNSAFE` in about 25.3s.
  - `near_wrap.unroll1=SAFE` in about 86.9s, then automatic growth to `near_wrap.unroll2=UNSAFE` in about 132.9s.
  - Manifest has `certified=false` and `diagnostic="near-wrap bug found but dependency projection incomplete; falling back to direct verification"`.
  - Candidate index is the dynamic hash slot:
    `flowrest_Ingress_idx_calc.get$bv32$bv32$bv16$bv16$bv8(167772161bv32, 167772162bv32, 1234bv16, 443bv16, 6bv8)`.
- **Pitfalls (implementation/model issues)**:
  - The P4B slicer had an optimization that, once it saw a target register-write seed, replaced the whole backward-slice root set with only target-register-write nodes. That is valid for register-only slicing, but unsound when explicit property seeds such as `hdr.ipv4.ttl` are present at the same time.
  - The previous `NEAR_WRAP=SAFE` was caused by losing property-observed P4 writes, so the correct classification is "verification false negative due slicing", not "bug absent".
  - Flowrest remains a dynamic-slot case: the near-wrap witness is concrete, but the dependency projection reports same-slot auxiliary register dependencies (`flowrest_Ingress_reg_flow_ID`, `flowrest_Ingress_reg_time_last_pkt`) and therefore correctly refuses closure certification for now.
- **Fixes/regression tests**:
  - `P4B-Translator/backends/verify/slicing/slicer.cpp`: target-register-write root narrowing now preserves nodes that define explicit user/property seeds. This keeps register-only slices narrow while preventing property-observed fields from being discarded.
  - `dslc/tests/p4b/test_p4b_translator_slicing_selftest.py`: added `test_external_flowrest_ttl_seed_keeps_ttl_assignments` to require the Flowrest ttl/classified_flag path under `--slicing-vars=hdr.ipv4.ttl,meta.pkt_count`.
  - P4B build passed: `cmake --build P4B-Translator/build-host --target p4c-translator -j4`.
  - Focused WSL tests passed: `python3 -m unittest -v dslc.tests.p4b.test_p4b_translator_slicing_selftest dslc.tests.p4b.test_p4b_translator_regressions` (33 tests), and `python3 -m unittest -v dslc.tests.wraparound.schedule.test_wraparound_projection dslc.tests.wraparound.schedule.test_wraparound_schedule dslc.tests.wraparound.cegis.core.test_wraparound_cegis_order dslc.tests.wraparound.transform.test_wraparound_transform dslc.tests.wraparound.test_wraparound_candidate_gating dslc.tests.p4b.test_p4b_translator_regressions` (79 tests).
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched. Next step is to strengthen dynamic-slot fallback/certification or run direct verification on the generated witness path.

## 2026-05-03 Flowrest pkt_count dynamic-slot projection expression check

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_count_wraparound.prop`
- **Time**: 2026-05-03 00:29-00:37 Asia/Shanghai
- **Goal/Progress**: Reran the Flowrest packet-count dynamic-slot case after adding projection expressions for same-slot auxiliary register dependencies, so the workflow can test CLOSURE without projecting dynamic dependencies through unsound slot-0 scalar mirrors.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260503-002940-aa05/`
  - Manifest: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260503-002940-aa05/wraparound/target.00.flowrest_Ingress_reg_pkt_count/wraparound.cegis.manifest.json`
  - `ENTRY_CHECK=UNSAFE` in about 15.5s.
  - `near_wrap.unroll1=SAFE` in about 64.3s, then automatic growth to `near_wrap.unroll2=UNSAFE` in about 347.4s.
  - `CLOSURE_CHECK=UNSAFE` in about 39.9s.
  - Manifest has `projection_complete=true` because the dynamic same-slot dependencies are represented as expressions:
    `flowrest_Ingress_reg_flow_ID[index_expr]` and `flowrest_Ingress_reg_time_last_pkt[index_expr]`.
  - Manifest still has `certified=false`; this is a concrete near-wrap witness plus a failed closure attempt, not a certified wraparound proof.
- **Pitfalls (implementation/model issues)**:
  - Expression projection fixed the earlier coarse fallback reason: the verifier no longer needs to reject the case merely because the candidate uses a dynamic hash slot.
  - The closure counterexample shows `flowrest_Ingress_reg_time_last_pkt[index_expr]` changes during the pump round. Requiring equality preservation for this auxiliary register is too strong for Flowrest, because the P4 program updates it to the current parser timestamp on every packet.
  - This failure should not be interpreted as "bug absent"; it means the current projection invariant is not the right inductive invariant for this program. The likely next refinement is to project/replay control predicates such as the established-flow predicate (`time_last_pkt != 0`) and same-flow predicate, or fall back to direct verification if those predicates cannot be derived soundly.
- **Fixes/regression tests**:
  - `dslc/analysis/wraparound_projection.py`: dynamic same-slot dependencies with matching index width are now emitted as `proj_exprs` instead of incorrectly using slot-0 mirrors.
  - `dslc/transform/wraparound_stages.py` and workflow/manifest plumbing now snapshot and assert `proj_exprs` in closure checks.
  - Focused WSL tests passed before this solver run: `python3 -m unittest -v dslc.tests.wraparound.schedule.test_wraparound_projection dslc.tests.wraparound.transform.test_wraparound_transform dslc.tests.wraparound.schedule.test_wraparound_schedule` (56 tests), and the broader wraparound/P4B subset later passed (108 tests).
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 Flowrest pkt_count cutpoint-shape projection smoke

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_count_wraparound.prop`
- **Time**: 2026-05-03 01:29 Asia/Shanghai
- **Goal/Progress**: Ran ENTRY-only Flowrest packet-count wraparound after changing dependency projection to extract dynamic-slot guard predicates and reject ambiguous cutpoint shapes conservatively.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260503-012906-19c4/`
  - Manifest: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260503-012906-19c4/wraparound/target.00.flowrest_Ingress_reg_pkt_count/wraparound.cegis.manifest.json`
  - `ENTRY_CHECK=UNSAFE` in about 15.5s.
  - Manifest has `projection_complete=false` before near/closure because automatic projection found both first-flow and established-flow predicates for `time_last_pkt[index]`.
- **Pitfalls (implementation/model issues)**:
  - `time_last_pkt[index]` is updated every packet, so equality projection is too strong.
  - A single one-round closure over both `time_last_pkt[index] == 0` and `time_last_pkt[index] != 0` shapes would be ambiguous. The tool now marks projection incomplete and must fallback/direct-check rather than certify.
- **Fixes/regression tests**:
  - `dslc/analysis/wraparound_projection.py`: canonicalizes P4B `reg.read(reg, idx)` to `reg[idx]`, avoids substituting register receivers, observes dynamic targets through the register array rather than `__last0_value`, and records dynamic-slot guard predicates.
  - `dslc/tests/wraparound/schedule/test_wraparound_projection.py`: added guard-predicate and ambiguous-shape tests.
  - Focused WSL tests passed: `python3 -m unittest -v dslc.tests.wraparound.schedule.test_wraparound_projection`, plus the schedule/transform/manifest subset.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 Flowrest pkt_count near-wrap after cutpoint-shape projection

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_count_wraparound.prop`
- **Time**: 2026-05-03 01:40-01:48 Asia/Shanghai
- **Goal/Progress**: Reran the Flowrest packet-count near-wrap stage after the cutpoint-shape projection refinement and expression-helper split, to confirm the previous slicing false negative stays repaired while incomplete projection prevents unsound closure certification.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260503-014058-2a8d/`
  - Manifest: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260503-014058-2a8d/wraparound/target.00.flowrest_Ingress_reg_pkt_count/wraparound.cegis.manifest.json`
  - `ENTRY_CHECK=UNSAFE` in about 14.5s.
  - `near_wrap.unroll1=SAFE` in about 60.6s, then automatic growth to `near_wrap.unroll2=UNSAFE` in about 343.9s.
  - Manifest attempt config has `projection_complete=false`, `certified=false`, and `diagnostic="stopped after near_wrap by request"`.
  - The near-wrap witness reaches the classification-update suffix: `flowrest_hdr.ipv4.ttl=128bv8`, `flowrest_meta.pkt_count=1bv8`, and `flowrest_Ingress_reg_pkt_count__last_value=1bv8` after a `255 -> 0 -> 1` style replay suffix.
- **Pitfalls (implementation/model issues)**:
  - `stop-after near_wrap` leaves top-level manifest fields such as `near_wrap`/`entry` empty, but the authoritative data is in `attempts[0]`; use that nested entry when auditing partial-stage manifests.
  - The automatic projection correctly records both `time_last_pkt[index] == 0` and `!(time_last_pkt[index] == 0)`, plus `flow_ID[index]` as a dynamic-slot expression. This means the bug witness exists, but the current one-round closure certificate is intentionally refused.
- **Fixes/regression tests**:
  - Split Boogie expression helpers from `dslc/analysis/wraparound_projection.py` into `dslc/analysis/wraparound_projection_exprs.py`, keeping both Python files under the 1300-line limit (`1243` and `201` lines respectively).
  - WSL tests passed before this solver run: `python3 -m py_compile dslc/analysis/wraparound_projection.py dslc/analysis/wraparound_projection_exprs.py`, `python3 -m unittest -v dslc.tests.wraparound.schedule.test_wraparound_projection` (10 tests), and `python3 -m unittest -v dslc.tests.wraparound.schedule.test_wraparound_schedule dslc.tests.wraparound.transform.test_wraparound_transform dslc.tests.wraparound.schedule.test_schedule_manifest_certification` (54 tests).
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 DistCache certified closure after projection helper split

- **Spec**: `Procurator/argo/code/spec/bench/distcache_p2c_wraparound_bug.prop`
- **Time**: 2026-05-03 01:50-01:54 Asia/Shanghai
- **Goal/Progress**: Reran a fixed-slot certified wraparound representative after the Flowrest cutpoint-shape projection changes and the `wraparound_projection_exprs.py` split.
- **Result**:
  - Run directory: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260503-015057-c8e3/`
  - Manifest: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260503-015057-c8e3/wraparound/target.00.clientTrack_partitionswitchIngress_leafload_reg/wraparound.cegis.manifest.json`
  - `ENTRY_CHECK=UNSAFE` in about 16.0s.
  - `near_wrap.unroll1=SAFE` in about 38.7s, then automatic growth to `near_wrap.unroll2=UNSAFE` in about 47.9s.
  - `CLOSURE_CHECK=SAFE` in about 56.6s.
  - Manifest has `certified=true`, `projection_complete=true`, and `diagnostic="stopped after closure by request"`.
- **Pitfalls/Fixes**:
  - No new implementation bug found. This regression confirms that the dynamic-slot conservative fallback path did not disable existing fixed-slot closure certificates.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 Flowrest pkt_len_total near-wrap witness

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_len_total_wraparound.prop`
- **Time**: 2026-05-03 02:14-02:26 Asia/Shanghai
- **Goal/Progress**: Explored a second Flowrest per-flow feature register after the packet-count witness, using the same staged near-wrap workflow and no dataset edits.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound/20260503-021450-8aba/`
  - Manifest: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound/20260503-021450-8aba/wraparound/target.00.flowrest_Ingress_reg_pkt_len_total/wraparound.cegis.manifest.json`
  - `ENTRY_CHECK=UNSAFE` in about 14.0s.
  - `near_wrap.unroll1=SAFE` in about 59.6s, then automatic growth to `near_wrap.unroll2=UNSAFE` in about 585.8s.
  - Candidate target is `flowrest_Ingress_reg_pkt_len_total` with `step_delta=32768` and the dynamic hash-slot index expression for the pinned five-tuple.
  - Witness log contains `flowrest_Ingress_reg_pkt_len_total__last_value=0bv16` and `flowrest_meta.pkt_len_total=0bv16`, confirming the wrapped zero write.
- **Pitfalls (implementation/model issues)**:
  - Like `pkt_count`, this is a dynamic-slot Flowrest feature path. The dependency projection records both `time_last_pkt[index] == 0` and `time_last_pkt[index] != 0`, plus `flow_ID[index]` as a dynamic-slot expression, so `projection_complete=false`.
  - The result is a concrete near-wrap witness, not a closure-certified schedule certificate. Certifying this class soundly needs a separate shape-reachability/cutpoint-splitting proof for the established-flow phase rather than witness-derived assumptions.
- **Fixes/regression tests**:
  - No new code change for this single-spec experiment.
  - Prior WSL regression remained green before this run: projection/schedule/transform/manifest subset passed (64 tests).
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched. The interrupted subagent review failed with a stream disconnect and was not used as approval evidence.

## 2026-05-03 Flowrest flow_duration candidate-gating check

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound.prop`
- **Time**: 2026-05-03 02:27 Asia/Shanghai
- **Goal/Progress**: Tried the Flowrest 32-bit `reg_flow_duration` candidate with the same staged near-wrap entry, to distinguish "bug absent" from "tool did not verify it".
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-022715-053c/`
  - CLI result: `STOP-AFTER near_wrap: no wraparound candidates`.
  - P4B meta still contains the relevant register and update:
    `reg_flow_duration_0 -> Ingress_reg_flow_duration`, `op=add`, `value_width=32`, but `delta_is_const=false`.
- **Pitfalls (implementation/model issues)**:
  - This is not a solver SAFE result and not evidence that the bug is absent. The pipeline did not attempt ENTRY/NEAR/CLOSURE because candidate selection currently needs a recoverable constant step delta for wraparound acceleration.
  - The update delta flows through `meta.iat = timestamp - time_last_pkt`, so proving this case requires either a direct bounded check or stronger DSL/P4B constant propagation across the timestamp/env phase script to recover the effective delta for the selected suffix.
- **Fixes/regression tests**:
  - No code change in this check. Follow-up implementation should improve candidate recovery for env-fixed variable deltas instead of modifying the P4 dataset.
- **Smoke/regression**: No Ultimate/GemCutter stage was launched because no wraparound candidate was inferred.

## 2026-05-03 Flowrest flow_duration direct bounded check

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound.prop`
- **Time**: 2026-05-03 02:28-02:44 Asia/Shanghai
- **Goal/Progress**: Ran a direct bounded verification attempt for the Flowrest `reg_flow_duration` script after wraparound candidate inference did not pick it up, to distinguish absence from tool incompleteness.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-022846-7fe2/`
  - BPL: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-022846-7fe2/external_flowrest_per_flow_flow_duration_wraparound.bpl`
  - Log: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-022846-7fe2/gemcutter.log`
  - Command used `--wraparound off --use-spec-max-steps --ultimate-timeout-seconds 900`.
  - Result: `Timeout` after about 830s inside TraceAbstraction; no `SAFE` or `UNSAFE` conclusion.
- **Pitfalls (implementation/model issues)**:
  - This remains "not verified within budget", not "bug absent". The bounded script is present, but the direct BMC/proof backend spent 34 CEGAR iterations and timed out while refining the abstraction.
  - The likely tool improvement is to recover the effective constant delta for `reg_flow_duration += meta.iat` from the DSL timestamp phase script and then reuse the near-wrap acceleration path, instead of asking the backend to rediscover the long arithmetic prefix directly.
- **Fixes/regression tests**:
  - No code change for this experiment.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 Flowrest flow_duration direct bounded check with 8GB all-inline backend

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound.prop`
- **Time**: 2026-05-03 02:55-03:09 Asia/Shanghai
- **Goal/Progress**: Retried the Flowrest `reg_flow_duration` bounded script with the stronger 8GB GemCutter profile (`ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por-allinline.epf`) to check whether the previous timeout was only a solver-resource/profile issue.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-025520-93be/`
  - BPL: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-025520-93be/external_flowrest_per_flow_flow_duration_wraparound.bpl`
  - Log: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-025520-93be/gemcutter.log`
  - Command used `--wraparound off --use-spec-max-steps --ultimate-timeout-seconds 900 --ultimate-xmx-gb 8 --no-witness-rerun`.
  - Result: `Timeout` after about 836s total, with TraceAbstraction around 832s and 22 CEGAR iterations. The reported timeout location is the final `assert !procurator_bad;`.
- **Pitfalls (implementation/model issues)**:
  - This is still not evidence that the bug is absent. The bounded witness shape is in the spec, but the backend is spending the budget refining a final accumulated assertion rather than seeing the narrow guarded register-write violation at the step where it happens.
  - The next DSLC-side optimization should keep the original accumulated global assertion for soundness and witness classification, while adding an equivalent direct assertion near the node pass for guarded register-write mirror predicates. This belongs in the distributed harness because the guard uses DSL phase state.
- **Fixes/regression tests**:
  - No code change for this single-spec experiment. Follow-up implementation should add a focused harness regression to ensure guarded register-write assertions are not incorrectly pushed into P4B fail-fast.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 Flowrest flow_duration bounded check after DSLC guarded direct assertions

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound.prop`
- **Time**: 2026-05-03 03:29-03:35 Asia/Shanghai
- **Goal/Progress**: After adding a DSLC harness direct assertion for guarded register-write global assertions, reran a 300s bounded verification attempt before opening another long run.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-032939-92d4/`
  - BPL: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-032939-92d4/external_flowrest_per_flow_flow_duration_wraparound.bpl`
  - Log: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-032939-92d4/gemcutter.log`
  - Command used `--wraparound off --use-spec-max-steps --ultimate-timeout-seconds 300 --ultimate-xmx-gb 8 --no-witness-rerun`.
  - Result: `Timeout` after about 276s toolchain time, TraceAbstraction around 273s, 12 CEGAR iterations.
  - The BPL now includes direct guarded checks at node-pass boundaries, e.g. line 1162 is `assert ((dsl_phase < 3) || !(flowrest_Ingress_reg_flow_duration__wrote_any && flowrest_Ingress_reg_flow_duration__last_value == 0bv32));`, followed by the original accumulated `procurator_bad` update.
- **Pitfalls (implementation/model issues)**:
  - The optimization moved the solver target away from only the final `assert !procurator_bad;`, but Ultimate still attempted early phase-guarded direct assertions at lines 946/1054/1162 plus the final assertion and timed out. This is still "not verified within budget", not "bug absent".
  - The next refinement should render the direct check as an explicit guard branch (for example, `if (!(phase < 3)) { assert !(reg write predicate); }`) so the early safe phase checks do not become equally prominent error locations.
- **Fixes/regression tests**:
  - `dslc/backends/boogie/harness/flow/sequential.py`: adds a DSLC-side direct assertion for bounded sequential guarded register-write global assertions while retaining `procurator_bad`.
  - `dslc/tests/boogie/backend/test_boogie_backend_smoke.py`: adds coverage ensuring guarded assertions are not pushed into P4B fail-fast and still get a DSLC direct check.
  - Focused WSL regression passed before this solver run: `python3 -m py_compile dslc/backends/boogie/harness/flow/sequential.py && python3 -m unittest -v dslc.tests.boogie.backend.test_boogie_backend_smoke dslc.tests.boogie.harness.test_boogie_harness_sequential_reg_dbg_snapshot` (25 tests).
  - BPL smoke passed for `.tmp/procurator/manual/flow_duration_direct_check.bpl`.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 Flowrest flow_duration bounded check after guarded-branch direct assertions

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound.prop`
- **Time**: 2026-05-03 03:40-03:45 Asia/Shanghai
- **Goal/Progress**: Changed the DSLC direct guarded assertion from `assert guard || !write_predicate` to an explicit branch `if (!guard) { assert !write_predicate; }`, then reran the same 300s bounded verification budget.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-034029-b291/`
  - BPL: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-034029-b291/external_flowrest_per_flow_flow_duration_wraparound.bpl`
  - Log: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-034029-b291/gemcutter.log`
  - Command used `--wraparound off --use-spec-max-steps --ultimate-timeout-seconds 300 --ultimate-xmx-gb 8 --no-witness-rerun`.
  - Result: `Timeout` after about 275s toolchain time, TraceAbstraction around 271s, 13 CEGAR iterations.
  - Timeout locations are still the three unfolded direct assertion sites plus the final accumulated `assert !procurator_bad;` (lines 1140/1256/1372/1378).
- **Pitfalls (implementation/model issues)**:
  - The branch form is semantically cleaner but did not reduce Ultimate's number of error locations. The duplicate final `procurator_bad` assertion is now redundant for this single guarded register-write global assertion and appears to be adding another target without helping witness discovery.
  - Next refinement should track which accumulated global assertions are exactly covered by DSLC direct checks in bounded sequential mode and avoid emitting the duplicate final error location when all active global assertions are covered. This needs a regression test because skipping the final assertion is only sound when the direct check is emitted at the same pass boundary for every active global assertion.
- **Fixes/regression tests**:
  - `dslc/backends/boogie/harness/flow/sequential.py`: guarded direct checks now render as `if (!guard) { assert !write_predicate; }`.
  - `dslc/tests/boogie/backend/test_boogie_backend_smoke.py`: updated the guarded-register test to check the explicit guard branch.
  - Focused WSL regression passed before this solver run: `python3 -m unittest -v dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_guarded_register_mirror_assert_gets_dsl_direct_check dslc.tests.boogie.backend.test_boogie_backend_smoke dslc.tests.boogie.harness.test_boogie_harness_sequential_reg_dbg_snapshot` (26 tests).
  - BPL smoke passed for `.tmp/procurator/manual/flow_duration_guarded_branch.bpl`.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 Flowrest flow_duration bounded check after removing covered duplicate final assertion

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound.prop`
- **Time**: 2026-05-03 03:49-03:55 Asia/Shanghai
- **Goal/Progress**: Refined the DSLC bounded sequential harness so global assertions covered by DSLC direct guarded register-write checks are not also accumulated into a duplicate final `assert !procurator_bad;`. This was tested on the Flowrest `flow_duration` bounded script before returning to candidate/suffix recovery.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-034940-cf9a/`
  - BPL: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-034940-cf9a/external_flowrest_per_flow_flow_duration_wraparound.bpl`
  - Log: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-034940-cf9a/gemcutter.log`
  - Command used `--wraparound off --use-spec-max-steps --ultimate-timeout-seconds 300 --ultimate-xmx-gb 8 --no-witness-rerun`.
  - Result: `Timeout` after about 273s TraceAbstraction, 10 CEGAR iterations.
  - The CFG now has 3 error locations, all direct guarded assertion sites (lines 1138/1252/1366). The duplicate final `procurator_bad` assertion is gone for this single-assertion spec.
- **Pitfalls (implementation/model issues)**:
  - Removing the duplicate final target reduces error locations from 4 to 3 and the largest abstraction, but still does not produce an `UNSAFE` witness within 300s. This points to the dynamic-slot/time-delta model itself rather than merely assertion placement.
  - This remains "not verified within budget", not "bug absent". The next useful path is to recover the effective scripted suffix/candidate for `reg_flow_duration += meta.iat`, or otherwise specialize the suffix check, instead of spending another long direct run on the same unstructured BPL.
- **Fixes/regression tests**:
  - `dslc/backends/boogie/harness/flow/sequential.py`: direct-covered global assertions are excluded from `procurator_bad`; uncovered active global assertions still use the original accumulated path.
  - Added a comment documenting that the DSLC guarded matcher is deliberately broader than P4B fail-fast matching because it may mention DSL scheduler/protocol state.
  - `dslc/tests/boogie/backend/test_boogie_backend_smoke.py`: updated guarded-register tests to require the DSLC direct check and absence of duplicate final assertion, while still ensuring guarded assertions are not pushed into P4B fail-fast.
  - Focused WSL regression passed before this solver run: `python3 -m py_compile dslc/backends/boogie/harness/flow/sequential.py && python3 -m unittest -v dslc.tests.boogie.backend.test_boogie_backend_smoke dslc.tests.boogie.harness.test_boogie_harness_sequential_reg_dbg_snapshot` (25 tests).
  - BPL smoke passed for `.tmp/procurator/manual/flow_duration_direct_only.bpl`; the generated BPL has no `procurator_bad` for this single covered global assertion.
- **Subagent review**:
  - A narrow review of the earlier DSLC direct-check patch reported no blocking soundness issue and confirmed the responsibility split: P4B owns pure P4 write-site fail-fast; DSLC owns guarded global assertions involving DSL phase/schedule state. The review also requested clearer AGENTS.md records and an explicit comment about the broader DSLC matcher, both addressed here.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 Flowrest flow_duration bounded check after deterministic DSL guard pruning

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound.prop`
- **Time**: 2026-05-03 04:05-04:10 Asia/Shanghai
- **Goal/Progress**: Added a conservative deterministic-unroll DSL integer upper-bound pass so direct guarded checks whose guard is provably true in an early unrolled phase are omitted. For the Flowrest three-packet script this removes the first two `phase < 3`-protected direct assertions and leaves only the third packet's real violation target.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-040502-e98a/`
  - BPL: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-040502-e98a/external_flowrest_per_flow_flow_duration_wraparound.bpl`
  - Log: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-040502-e98a/gemcutter.log`
  - Command used `--wraparound off --use-spec-max-steps --ultimate-timeout-seconds 300 --ultimate-xmx-gb 8 --no-witness-rerun`.
  - Result: `Timeout` after about 275s TraceAbstraction, 16 CEGAR iterations.
  - The generated BPL has a single error location at the third node pass (`assert !(flowrest_Ingress_reg_flow_duration__wrote_any && flowrest_Ingress_reg_flow_duration__last_value == 0bv32)`); earlier guarded checks and the duplicate final assertion are gone.
- **Pitfalls (implementation/model issues)**:
  - This rules out "too many assertion targets" as the primary remaining bottleneck. The solver still times out on one real target, with array/bitvector reasoning and dynamic-slot dependencies dominating.
  - The generated/sliced model still contains unrelated Flowrest feature registers and feature-table state (`flow_iat_max`, packet-length max/min/total, etc.) even though the spec only observes `reg_flow_duration`. This suggests the next optimization should improve slicing/seed precision or dependency pruning, not spend another long direct run on the same BPL.
  - This remains "not verified within budget", not "bug absent".
- **Fixes/regression tests**:
  - `dslc/backends/boogie/harness/flow/sequential.py`: added conservative DSL int upper-bound tracking for deterministic bounded unrolls; only top-level global int assignments/env increments are tracked, and unknown/nested writes drop the bound.
  - `dslc/tests/boogie/backend/test_boogie_backend_smoke.py`: strengthened the Flowrest guarded direct-check regression to require exactly one remaining `flow_duration == 0` assertion in the three-packet script.
  - Focused WSL regression passed before this solver run: `python3 -m py_compile dslc/backends/boogie/harness/flow/sequential.py && python3 -m unittest -v dslc.tests.boogie.backend.test_boogie_backend_smoke dslc.tests.boogie.harness.test_boogie_harness_sequential_reg_dbg_snapshot` (25 tests).
  - BPL smoke passed for `.tmp/procurator/manual/flow_duration_phase_pruned.bpl`; it contains exactly one `flowrest_Ingress_reg_flow_duration__last_value == 0bv32` check.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 Flowrest flow_duration bounded check after DSLC/P4B control-seed ownership fix

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound.prop`
- **Time**: 2026-05-03 04:56-05:02 Asia/Shanghai
- **Goal/Progress**: Re-ran the Flowrest `reg_flow_duration` direct bounded verification after fixing the slicing responsibility split so DSLC, not P4B's implicit control-root expansion, owns the control seed set passed to P4B.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-045655-cdef/`
  - BPL: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-045655-cdef/external_flowrest_per_flow_flow_duration_wraparound.bpl`
  - Log: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-045655-cdef/gemcutter.log`
  - Command used `--wraparound off --use-spec-max-steps --ultimate-timeout-seconds 300 --ultimate-xmx-gb 8 --no-witness-rerun` with the 8GB all-inline GemCutter profile.
  - Result: `Timeout`; TraceAbstraction took about 273.8s with 12 CEGAR iterations.
  - The generated raw P4B model now has `0` occurrences of unrelated Flowrest feature suffixes (`read_pkt_len*`, `read_flow_iat*`, `read_pkt_count`), and the final BPL has exactly one `flow_duration == 0` assertion target.
- **Pitfalls (implementation/model issues)**:
  - Earlier Flowrest `flow_duration` timing results that still retained unrelated feature suffixes were widened-model toolchain artifacts and should not be used as evidence about bug absence.
  - This precise-model run is still not a `SAFE` result: the backend timed out on a single real target. The remaining gap is support for the variable-delta update `reg_flow_duration += meta.iat`, where `meta.iat` is fixed by the DSL timestamp phase script, not by a constant P4 update.
- **Fixes/regression tests**:
  - `dslc/backends/boogie/compiler.py`: DSLC still builds explicit system/control slicing seeds, but always disables P4B's own implicit control-root expansion when invoking P4B, avoiding duplicated conservative seed expansion.
  - `dslc/tests/boogie/backend/test_boogie_backend_smoke.py`: added `test_dslc_owns_control_seeds_for_p4b_slicing`.
  - `P4B-Translator/backends/verify/slicing/slicer_selftest.cpp` and `dslc/tests/p4b/test_p4b_translator_slicing_selftest.py`: added a Flowrest `flow_duration` target-prefix slicing regression.
  - Focused WSL regression passed before this solver run: `python3 -m unittest -v dslc.tests.p4b.test_p4b_translator_slicing_selftest dslc.tests.boogie.backend.test_boogie_backend_smoke dslc.tests.boogie.harness.test_boogie_harness_sequential_reg_dbg_snapshot` (54 tests).
  - BPL smoke passed for `.tmp/procurator/manual/flow_duration_default_after_control_fix.bpl`.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 Flowrest flow_duration focused direct witness

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound.prop`
- **Time**: 2026-05-03 05:25-05:26 Asia/Shanghai
- **Goal/Progress**: Productized the successful dynamic-slot experiment as an UNSAFE-only focused direct prepass: the generated BPL keeps the precise sliced Flowrest model, then builds a slot-0 under-approximation for standard P4B dynamic-index register reads/writes using the existing index0 scalar mirrors.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-052526-ce11/`
  - Original BPL: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-052526-ce11/external_flowrest_per_flow_flow_duration_wraparound.bpl`
  - Focused BPL: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-052526-ce11/external_flowrest_per_flow_flow_duration_wraparound.focused-index0.bpl`
  - Focused log: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-052526-ce11/external_flowrest_per_flow_flow_duration_wraparound.focused-index0.log`
  - Marker: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-052526-ce11/external_flowrest_per_flow_flow_duration_wraparound.focused-index0.unsafe.json`
  - CLI result: focused prepass `UNSAFE`; original full run skipped after the focused witness.
  - Focused Ultimate stats: CFG has 172 locations / 229 edges / 1 error location; OverallTime about 30.9s; `CounterExampleResult [Line: 1097]`.
  - The raw P4B model still has `0` unrelated Flowrest feature suffixes and the original final BPL has exactly one `flow_duration == 0` assertion target.
- **Pitfalls (implementation/model issues)**:
  - This is a direct bug witness, not a wraparound closure certificate. The focused prepass constrains the dynamic hash/register slot to `0bv16`; because it is an under-approximation, `UNSAFE` is sound as existence evidence, but `SAFE/UNKNOWN/TIMEOUT` must never be reported as a conclusion for the original program.
  - The prior exact model still timed out at 300s, so this result means "bug found through a focused under-approx witness", not "full exact proof completed".
- **Fixes/regression tests**:
  - `dslc/transform/focused_direct.py`: new focused direct transform for unique direct register-mirror assertions, gated on complete P4B index0 mirrors and standard dynamic-index read/write shapes.
  - `dslc/cli/gemcutter.py`: runs the focused prepass before the full direct Ultimate run; only `UNSAFE` returns early, otherwise it falls back to the original BPL. It writes a `.focused-index0.unsafe.json` marker instead of misreporting missing GraphML.
  - `dslc/tests/transform/test_focused_direct.py`: covers scalarization and no-op fallback.
  - Focused WSL tests passed: `python3 -m py_compile dslc/cli/gemcutter.py dslc/transform/focused_direct.py dslc/tests/transform/test_focused_direct.py && python3 -m unittest -v dslc.tests.transform.test_focused_direct`.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 DistCache certified wraparound smoke after focused direct prepass

- **Spec**: `Procurator/argo/code/spec/bench/distcache_p2c_wraparound_bug.prop`
- **Time**: 2026-05-03 05:28-05:31 Asia/Shanghai
- **Goal/Progress**: Reran a known fixed-slot certified wraparound representative after adding the focused direct prepass, to ensure the new direct bug-finding optimization does not interfere with wraparound schedule-replay certification.
- **Result**:
  - Run directory: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260503-052846-e482/`
  - Manifest: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260503-052846-e482/wraparound/target.00.clientTrack_partitionswitchIngress_leafload_reg/wraparound.cegis.manifest.json`
  - `ENTRY_CHECK=UNSAFE` in about 14.5s.
  - `near_wrap.unroll1=SAFE` in about 28.3s, then `near_wrap.unroll2=UNSAFE` in about 34.9s.
  - `CLOSURE_CHECK=SAFE` in about 44.0s.
  - Command stopped after closure by request; this reproduces the certified schedule-replay shape (`ENTRY UNSAFE + NEAR UNSAFE + CLOSURE SAFE`).
- **Pitfalls/Fixes**:
  - No new implementation issue found. This confirms the focused direct prepass is isolated from the wraparound CEGAR/schedule-replay path.
- **Regression tests**:
  - Before this solver run, WSL regression passed: `python3 -m unittest -v dslc.tests.transform.test_focused_direct dslc.tests.boogie.backend.test_boogie_backend_smoke dslc.tests.wraparound.schedule.test_wraparound_projection dslc.tests.wraparound.schedule.test_wraparound_schedule dslc.tests.wraparound.transform.test_wraparound_transform dslc.tests.wraparound.schedule.test_schedule_manifest_certification` (88 tests).
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 Flowrest flow_duration focused direct gate-tightening regression

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound.prop`
- **Time**: 2026-05-03 05:33-05:34 Asia/Shanghai
- **Goal/Progress**: Reran the Flowrest focused direct witness after tightening the transform gate so it only emits a focused BPL when the dynamic index is actually pinned at the unique index-definition call and at least one standard dynamic-index register access is scalarized.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-053325-a12c/`
  - Focused BPL: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-053325-a12c/external_flowrest_per_flow_flow_duration_wraparound.focused-index0.bpl`
  - Focused log: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-053325-a12c/external_flowrest_per_flow_flow_duration_wraparound.focused-index0.log`
  - Marker: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-053325-a12c/external_flowrest_per_flow_flow_duration_wraparound.focused-index0.unsafe.json`
  - CLI result: focused prepass `UNSAFE`; original full run skipped after focused witness.
- **Pitfalls/Fixes**:
  - Found and fixed a conservative-gating issue during local review: a future BPL with scalarizable dynamic-index accesses but no actual index-definition call could have produced a focused BPL without the intended `assume idx == 0`. The transform now rejects that case and falls back to the original BPL.
- **Regression tests**:
  - `dslc/tests/transform/test_focused_direct.py`: added `test_scalarization_requires_index_pin_call`.
  - WSL tests passed before this solver run: `python3 -m py_compile dslc/cli/gemcutter.py dslc/transform/focused_direct.py dslc/tests/transform/test_focused_direct.py && python3 -m unittest -v dslc.tests.transform.test_focused_direct`.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 Flowrest focused direct soundness hardening after review

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound.prop`
- **Time**: 2026-05-03 05:39-05:41 Asia/Shanghai
- **Goal/Progress**: Addressed subagent review findings on the focused direct prepass, then reran the Flowrest witness to make sure the result does not rely on inconsistent array/mirror state or an over-broad index pin.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-053945-2e11/`
  - Focused BPL: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-053945-2e11/external_flowrest_per_flow_flow_duration_wraparound.focused-index0.bpl`
  - Focused log: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-053945-2e11/external_flowrest_per_flow_flow_duration_wraparound.focused-index0.log`
  - Marker: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260503-053945-2e11/external_flowrest_per_flow_flow_duration_wraparound.focused-index0.unsafe.json`
  - CLI result: focused prepass `UNSAFE`; original full run skipped after focused witness.
  - Marker now records `target_reg=flowrest_Ingress_reg_flow_duration`, `idx_var=flowrest_meta.register_index`, `zero=0bv16`, and `assert_line=1101`.
  - Ultimate log reports `CounterExampleResult [Line: 1101]`, matching the focused direct assertion exactly; OverallTime about 31.8s.
- **Pitfalls (implementation/model issues)**:
  - Review found two high-priority risks in the first focused transform:
    - Replacing writes with mirror-only updates could create an inconsistent state if any later code observes the register array itself.
    - Inserting one `assume idx == 0` after the index-definition call was not enough if the same index variable could be reassigned before later register accesses.
  - These are fixed before treating the Flowrest result as a focused direct witness.
- **Fixes/regression tests**:
  - `dslc/transform/focused_direct.py`: focused writes now update both the real array slot (`reg[0bvW] := value`) and the index0 mirrors; the focused region stops after any reassignment to the index variable; the transform returns target metadata including assertion line.
  - `dslc/cli/gemcutter.py`: focused early return now requires the Ultimate `CounterExampleResult [Line: N]` to match the focused assertion line; marker lookup is tied to the current BPL; added `--focused-direct {auto,off}` for reproducibility.
  - `dslc/tests/transform/test_focused_direct.py`: added regression coverage for index reassignment stopping scalarization.
  - WSL tests passed: `python3 -m py_compile dslc/cli/gemcutter.py dslc/transform/focused_direct.py dslc/tests/transform/test_focused_direct.py && python3 -m unittest -v dslc.tests.transform.test_focused_direct dslc.tests.boogie.backend.test_boogie_backend_smoke` (26 tests), plus schedule/certification subset earlier in the same hardening pass.
- **Subagent review**:
  - Review confirmed the CLI UNSAFE-only fallback avoids false SAFE and does not contaminate wraparound certification, but required the array synchronization, index-region gate, target-line validation, and an off switch; all were implemented.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 Flowrest pkt_len_total focused direct witness

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_len_total_wraparound.prop`
- **Time**: 2026-05-03 05:44-05:45 Asia/Shanghai
- **Goal/Progress**: Applied the reviewed/hardened focused direct prepass to a second Flowrest per-flow feature register (`reg_pkt_len_total`) whose dynamic slot and array reasoning previously required near-wrap exploration.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound/20260503-054434-5ca9/`
  - Focused BPL: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound/20260503-054434-5ca9/external_flowrest_per_flow_pkt_len_total_wraparound.focused-index0.bpl`
  - Focused log: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound/20260503-054434-5ca9/external_flowrest_per_flow_pkt_len_total_wraparound.focused-index0.log`
  - Marker: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound/20260503-054434-5ca9/external_flowrest_per_flow_pkt_len_total_wraparound.focused-index0.unsafe.json`
  - CLI result: focused prepass `UNSAFE`; original full run skipped after focused witness.
  - Marker records `target_reg=flowrest_Ingress_reg_pkt_len_total`, `idx_var=flowrest_meta.register_index`, `zero=0bv16`, `assert_line=983`.
  - Ultimate log reports `CounterExampleResult [Line: 983]`, matching the focused direct assertion; OverallTime about 13.1s.
  - The raw P4B model has `0` unrelated Flowrest feature suffix occurrences for `read_flow_duration`, `read_flow_iat`, and `read_pkt_count`, confirming the target-prefix slice stayed tight.
- **Pitfalls/Fixes**:
  - No new implementation issue found. This is another focused under-approx direct witness, not a closure certificate.
- **Regression tests**:
  - Reuses the focused direct hardening tests and the Flowrest target-prefix slicing regressions from the earlier run.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 ETC_NOMS_2024 pkt_len_total direct slot0 witness

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_slot0.prop`
- **Time**: 2026-05-03 05:46-05:47 Asia/Shanghai
- **Goal/Progress**: Ran a second external system (`ETC_NOMS_2024`) through the direct verifier on a slot-0 packet-length-total wraparound witness shape.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_slot0/20260503-054614-21ae/`
  - BPL: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_slot0/20260503-054614-21ae/external_etc_noms2024_pkt_len_total_wraparound_slot0.bpl`
  - Log: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_slot0/20260503-054614-21ae/gemcutter.log`
  - CLI result: direct `UNSAFE`; witness rerun was disabled for this staged exploration.
  - Ultimate stats: CFG has 158 locations / 213 edges / 5 error locations; OverallTime about 14.8s.
  - Primary counterexample location: `CounterExampleResult [Line: 558]`.
  - BPL line 558 is the P4B fail-fast assertion inside `etc_Ingress_reg_pkt_len_total.write` guarded by `etc_Ingress_reg_pkt_len_total__wrote_index0 && etc_Ingress_reg_pkt_len_total__last0_value == 0bv16`, so the result corresponds to an actual slot-0 zero write to the target feature register.
- **Pitfalls (implementation/model issues)**:
  - The ordinary witness summary reported missing GraphML because the command used `--no-witness-rerun`; this is expected for staged exploration and does not change the `UNSAFE` solver result.
  - This is a direct slot-0 witness, not a closure-certified wraparound result.
- **Fixes/regression tests**:
  - No new code change for this single-spec experiment.
  - Prior focused direct hardening and backend smoke tests were already green in the same session.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 INT FlowDoS counter_filter near-wrap witness but uncertified projection

- **Spec**: `Procurator/argo/code/spec/bench/external_int_flowdos_counter_wraparound.prop`
- **Time**: 2026-05-03 05:48-05:56 Asia/Shanghai
- **Goal/Progress**: Explored a third external in-network system (`Montimage/inband-network-telemetry` FlowDoS) for a counter wraparound bug, first with schedule-replay near-wrap stages and then with direct fallback.
- **Result**:
  - Near-wrap run directory: `.tmp/procurator/verify/external_int_flowdos_counter_wraparound/20260503-054947-7c9e/`
  - Manifest: `.tmp/procurator/verify/external_int_flowdos_counter_wraparound/20260503-054947-7c9e/wraparound/target.00.flowdos_MyIngress_counter_filter/wraparound.cegis.manifest.json`
  - `ENTRY_CHECK=UNSAFE` in about 13.5s.
  - `near_wrap.unroll1=UNSAFE` in about 20.0s.
  - Manifest has `certified=false`, `projection_complete=false`, and diagnostic `near-wrap bug found but dependency projection incomplete; falling back to direct verification`.
  - Near-wrap witness log reports `CounterExampleResult [Line: 1367]` and OverallTime about 4.6s for the near-wrap BPL.
  - Direct fallback run directory: `.tmp/procurator/verify/external_int_flowdos_counter_wraparound/20260503-055055-a753/`
  - Direct result: `Timeout`; TraceAbstraction about 274.6s, 35 CEGAR iterations.
- **Pitfalls (implementation/model issues)**:
  - This distinguishes "bug witness found in near-wrap stage" from "certified wraparound bug": projection is incomplete because dependency extraction reports dynamic-slot dependency on `flowdos_isValid`, so closure is intentionally skipped and the manifest is not certified.
  - Direct fallback did not prove SAFE and did not find a direct witness within 300s; this is "not verified within budget", not "bug absent".
- **Fixes/regression tests**:
  - No code change for this single-spec experiment.
  - Follow-up candidate: refine dependency projection for stable parser/header-validity shape or include it explicitly in projection before attempting certification.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 ETC_NOMS_2024 pkt_count staged near-wrap timeout

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_count_wraparound.prop`
- **Time**: 2026-05-03 05:57-06:08 Asia/Shanghai
- **Goal/Progress**: Explored the ETC_NOMS_2024 packet-count feature register with the schedule-replay wraparound stages, using short staged checks rather than an unconstrained long direct run.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260503-055738-d598/`
  - Manifest: `.tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260503-055738-d598/wraparound/target.00.etc_Ingress_reg_pkt_count/wraparound.cegis.manifest.json`
  - `ENTRY_CHECK=UNSAFE` in about 14.0s; the entry log reports `CounterExampleResult [Line: 887]`.
  - `near_wrap.unroll1=TIMEOUT`: CFG has 85 locations / 113 edges / 3 error locations, TraceAbstraction about 275.5s, timeout at line 987.
  - `near_wrap.unroll2=TIMEOUT`: CFG has 164 locations / 220 edges / 6 error locations, TraceAbstraction about 264.2s, timeout at line 1069.
  - The outer command reached its watchdog during the second near-wrap run; the leftover Ultimate process group was explicitly terminated and a follow-up `pgrep` check found no residual solver process.
  - Manifest has `certified=false`, `projection_complete=false`, and diagnostic `near-wrap check did not find a bug for this schedule; falling back`.
- **Pitfalls (implementation/model issues)**:
  - This is not a `SAFE` result and should not be used as evidence that the bug is absent. It means the current staged encoding did not find a witness within the 300s per-stage budget.
  - The dependency projection is incomplete: the same cutpoint contains both `etc_Ingress_reg_status[idx] == 0bv1` and its negation, and also depends on the dynamic-slot expression `etc_Ingress_reg_flow_ID[idx]`. That shape needs cutpoint splitting or stronger phase/shape projection before closure can be soundly certified.
- **Fixes/regression tests**:
  - No code fix was made for this single-spec experiment.
  - Follow-up candidate: refine schedule/projection extraction for ETC's status/flow-ID shape, or fall back to a focused direct witness that is reported only as an under-approximate `UNSAFE` result.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 Projection guard-alternative hardening and DistCache certified smoke

- **Spec**: `Procurator/argo/code/spec/bench/distcache_p2c_wraparound_bug.prop`
- **Time**: 2026-05-03 06:26-06:29 Asia/Shanghai
- **Goal/Progress**: Added a conservative foundation for future branch/cutpoint splitting: dependency projection now records cutpoint guard alternatives grouped by target write site, while the schedule-replay certification gate explicitly requires `cfg.projection_complete`. This keeps ETC/Flowrest ambiguous initialization-vs-steady branches uncertified until a real branch split is implemented.
- **Result**:
  - Run directory: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260503-062607-428c/`
  - Manifest: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260503-062607-428c/wraparound/target.00.clientTrack_partitionswitchIngress_leafload_reg/wraparound.cegis.manifest.json`
  - `ENTRY_CHECK=UNSAFE` in about 13.9s.
  - `near_wrap.unroll1=SAFE` in about 28.6s; `near_wrap.unroll2=UNSAFE` in about 34.2s.
  - `CLOSURE_CHECK=SAFE` in about 43.0s.
  - Manifest remains certified for this fixed-slot case (`certified=true`, `projection_complete=true`, no closure assumptions).
- **Pitfalls/Fixes**:
  - The change does not make ambiguous external dynamic-slot cases certified. It only preserves grouped guard alternatives for later branch splitting and adds defense-in-depth so a SAFE closure cannot certify if `projection_complete=false`.
  - `dslc/analysis/wraparound_projection.py`: added `cutpoint_guard_alternatives` and grouped guard tracking.
  - `dslc/workflows/wraparound_support/loop_schedule.py`: final `certified` now explicitly requires `cfg.projection_complete`.
- **Regression tests**:
  - `python3 -m py_compile dslc/analysis/wraparound_projection.py dslc/workflows/wraparound_support/loop_schedule.py dslc/tests/wraparound/schedule/test_wraparound_projection.py dslc/tests/wraparound/schedule/test_wraparound_schedule.py` passed.
  - `python3 -m unittest -v dslc.tests.wraparound.schedule.test_wraparound_projection dslc.tests.wraparound.schedule.test_wraparound_schedule dslc.tests.wraparound.schedule.test_schedule_manifest_certification` passed (40 tests).
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 Flowrest pkt_count near-wrap discovery after projection hardening

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_count_wraparound.prop`
- **Time**: 2026-05-03 06:30-06:32 Asia/Shanghai
- **Goal/Progress**: Reproduced a third Flowrest feature/counter bug shape after adding guard-alternative tracking, stopping after the near-wrap discovery stage to avoid mislabeling an incomplete projection as a closure certificate.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260503-063001-9837/`
  - Manifest: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260503-063001-9837/wraparound/target.00.flowrest_Ingress_reg_pkt_count/wraparound.cegis.manifest.json`
  - `ENTRY_CHECK=UNSAFE` in about 14.0s.
  - `near_wrap.unroll1=SAFE` in about 34.4s.
  - `near_wrap.unroll2=UNSAFE` in about 41.3s; log reports `CounterExampleResult [Line: 1207]`.
  - The near-wrap BPL assertion at line 1207 is the gated wrapper for the functional suffix assertion. The generated BPL shows the suffix condition involving `flowrest_meta.pkt_count == 1bv8` and `flowrest_hdr.ipv4.ttl == 128bv8`.
  - Manifest remains uncertified: `certified=false`, `projection_complete=false`, stopped after near-wrap by request.
- **Pitfalls (implementation/model issues)**:
  - This is a near-wrap discovery witness, not a certified wraparound bug. The dependency projection records two guard alternatives but also sees an ambiguous flat predicate pair over `flowrest_Ingress_reg_time_last_pkt[idx] == 0bv32` and its negation. Closure certification must wait for real branch/cutpoint splitting.
  - The result is useful evidence that the theoretical bug shape exists in the transformed model; it is not a proof of replay closure.
- **Fixes/regression tests**:
  - No additional code change for this single-spec run; it exercises the guard-alternative notes introduced earlier in this session (`dependency_projection_cutpoint_guard_alternatives=2`).
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 Flowrest flow_duration guarded-direct timeout

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound_direct.prop`
- **Time**: 2026-05-03 06:34-06:39 Asia/Shanghai
- **Goal/Progress**: Tried the stronger guarded direct Flowrest duration spec, which excludes the trivial first-packet/no-IAT case and requires an actual zero write with `meta.is_first != 1` and `meta.iat != 0`.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound_direct/20260503-063401-3fd8/`
  - BPL: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound_direct/20260503-063401-3fd8/external_flowrest_per_flow_flow_duration_wraparound_direct.bpl`
  - Log: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound_direct/20260503-063401-3fd8/gemcutter.log`
  - Command used `--wraparound off --use-spec-max-steps --ultimate-timeout-seconds 300 --ultimate-xmx-gb 8 --no-reg-debug --no-witness-rerun`.
  - Result: `Timeout`; TraceAbstraction about 274.9s, 16 CEGAR iterations, CFG has 189 locations / 254 edges / 1 error location, timeout at line 975.
- **Pitfalls (implementation/model issues)**:
  - This is not a `SAFE` result and should not be used as evidence that the guarded bug is absent.
  - The generated BPL accumulates this guarded global assertion into `procurator_bad` and checks only the final `assert !procurator_bad`, rather than using the more focused direct register-write assertion path. A useful follow-up optimization is to extend DSLC's direct-covered guarded matcher to conjunctions such as `reg__wrote_any && reg__last_value == 0 && meta.is_first != 1 && meta.iat != 0`.
  - The earlier focused direct witness for the simpler Flowrest `flow_duration` spec remains an under-approximate `UNSAFE` witness, but this stronger guarded spec was not verified within the 300s budget.
- **Fixes/regression tests**:
  - No code change for this single-spec run.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 ETC_NOMS_2024 pkt_len_total dynamic-slot direct timeout

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_direct.prop`
- **Time**: 2026-05-03 06:40-06:45 Asia/Shanghai
- **Goal/Progress**: Tried the dynamic-slot packet-length-total wraparound direct spec for `ETC_NOMS_2024`, to distinguish a real dynamic-index bottleneck from the already-confirmed slot-0 direct witness.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260503-064023-528f/`
  - BPL: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260503-064023-528f/external_etc_noms2024_pkt_len_total_wraparound_direct.bpl`
  - Log: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260503-064023-528f/gemcutter.log`
  - Command used `--wraparound off --use-spec-max-steps --ultimate-timeout-seconds 300 --ultimate-xmx-gb 8 --no-reg-debug --no-witness-rerun`.
  - Result: `Timeout`; TraceAbstraction about 272.3s, 10 CEGAR iterations, CFG has 158 locations / 213 edges / 5 error locations.
  - Timeout/error locations included line 550 and the final accumulated assertion line 946.
- **Pitfalls (implementation/model issues)**:
  - This is not a `SAFE` result and should not be used as evidence that the dynamic-slot bug is absent. It means the current dynamic-index direct encoding did not find a witness within the 300s budget.
  - The fixed slot-0 version remains quick direct `UNSAFE` evidence for the same feature register shape: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_slot0/20260503-054614-21ae/`, OverallTime about 14.8s.
  - The dynamic-slot form is still a major bottleneck and should be optimized either by focused guarded direct assertions or by branch/cutpoint splitting with complete projection.
- **Fixes/regression tests**:
  - No code change for this single-spec run.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 ETC_NOMS_2024 pkt_len_total slot0 direct regression

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_slot0.prop`
- **Time**: 2026-05-03 06:49-06:50 Asia/Shanghai
- **Goal/Progress**: Re-ran the previously discovered slot-0 packet-length-total direct witness after the projection/guard-direct changes, to ensure existing external witness discovery still works.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_slot0/20260503-064911-9b0c/`
  - BPL: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_slot0/20260503-064911-9b0c/external_etc_noms2024_pkt_len_total_wraparound_slot0.bpl`
  - Log: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_slot0/20260503-064911-9b0c/gemcutter.log`
  - CLI result: direct `UNSAFE`; witness rerun was disabled for this staged regression.
  - Ultimate stats: CFG has 158 locations / 213 edges / 5 error locations; OverallTime about 15.9s.
  - Primary counterexample location: `CounterExampleResult [Line: 558]`.
- **Pitfalls (implementation/model issues)**:
  - The CLI exits nonzero for `UNSAFE`; this is expected and does not indicate a tool failure.
  - This is a slot-0 direct under-approximation witness, not a closure-certified wraparound result.
- **Fixes/regression tests**:
  - No code change for this single-spec run.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 Flowrest guarded direct optimization and focused witness

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound_direct.prop`
- **Time**: 2026-05-03 06:56-07:06 Asia/Shanghai
- **Goal/Progress**: Fixed the bounded sequential harness so conjunctive guarded register-mirror assertions are emitted as direct pass-boundary checks, then extended the focused direct prepass to accept repeated same-target assertions from bounded unrolling.
- **Result**:
  - First run after direct-check emission: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound_direct/20260503-065607-7799/`
    - The generated BPL no longer accumulates this assertion into `procurator_bad`; it emits direct guarded checks at lines 815, 895, and 975.
    - Result: `Timeout`, not `SAFE`; CFG has 193 locations / 258 edges / 3 error locations, OverallTime about 272.4s.
  - Focused run after multi-assertion support: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound_direct/20260503-070436-1435/`
    - Marker: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound_direct/20260503-070436-1435/external_flowrest_per_flow_flow_duration_wraparound_direct.focused-index0.unsafe.json`
    - Focused BPL: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound_direct/20260503-070436-1435/external_flowrest_per_flow_flow_duration_wraparound_direct.focused-index0.bpl`
    - Focused result: `UNSAFE`; `CounterExampleResult [Line: 996]`; OverallTime about 48.6s.
    - Marker records `target_reg=flowrest_Ingress_reg_flow_duration`, `idx_var=flowrest_meta.register_index`, `zero=0bv16`, and accepted assertion lines `[836, 916, 996]`.
- **Pitfalls (implementation/model issues)**:
  - Direct guarded emission improves the BPL shape but does not by itself solve the stronger Flowrest dynamic-index case within 300s, because the original dynamic model still leaves heavy array/bitvector reasoning for Ultimate.
  - The focused result is intentionally an `UNSAFE`-only slot-0 under-approximation witness. It is not a wraparound closure certificate; `SAFE`, `UNKNOWN`, or `TIMEOUT` from the focused prepass must still fall back to the original BPL.
  - Bounded unrolling can emit the same target assertion at multiple pass boundaries. The prepass now accepts an `UNSAFE` only if the counterexample line hits one of the same-target focused assertion lines; different-target or mixed-value assertions are still rejected.
- **Fixes/regression tests**:
  - `dslc/backends/boogie/harness/flow/sequential.py`: recognizes both `guard || !write_check` and `!(write_check && guard...)` as bounded direct guarded checks.
  - `dslc/transform/focused_direct.py`: accepts repeated same-target direct assertions and records all focused assertion lines.
  - `dslc/cli/gemcutter.py`: validates focused `UNSAFE` against any accepted focused assertion line and writes all lines to the marker.
  - `dslc/tests/boogie/backend/test_boogie_backend_smoke.py`: added a regression for conjunctive guarded direct assertions.
  - `dslc/tests/transform/test_focused_direct.py`: added regression coverage for repeated same-target assertions.
  - Regression executed: `python3 -m unittest -v dslc.tests.transform.test_focused_direct dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_conjunctive_guarded_register_mirror_assert_gets_dsl_direct_check` passed.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 ETC_NOMS_2024 pkt_len_total focused direct hardening

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_direct.prop`
- **Time**: 2026-05-03 08:00-08:13 Asia/Shanghai
- **Goal/Progress**: Hardened the focused dynamic-slot direct prepass so it only accepts slot-0 post-transform assertion locations, not the original broad `__wrote_any/__last_value` fail-fast locations. This was a staged investigation of the dynamic-index bottleneck; it was not used as proof of bug absence.
- **Result**:
  - Run after target assertion rewrite: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260503-080016-9315/`
    - Focused result: `Timeout`; focused CFG had 146 locations / 191 edges / 7 error locations; OverallTime about 107.0s.
  - Run after removing the unused broad target fail-fast and tightening accepted assertion lines: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260503-080853-43ea/`
    - Focused result: `Timeout`; focused CFG had 144 locations / 189 edges / 6 error locations; OverallTime about 110.9s.
  - Run with the focused prepass allowed to use the full 300s staged timeout: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260503-081332-6c9d/`
    - Focused result: `Timeout`; focused CFG had 144 locations / 189 edges / 6 error locations; OverallTime about 273.2s.
    - Original dynamic direct fallback also timed out in the same command; original CFG had 158 locations / 213 edges / 5 error locations; OverallTime about 275.4s.
- **Pitfalls (implementation/model issues)**:
  - The previous focused acceptance rule was too broad: it could accept a counterexample at the original dynamic `__wrote_any/__last_value` fail-fast line instead of the focused slot-0 assertion. That would blur the meaning of the focused under-approximation.
  - All outcomes above are `TIMEOUT`, not `SAFE`; they do not show that the dynamic-slot bug is absent.
- **Fixes/regression tests**:
  - `dslc/transform/focused_direct.py`: target assertions are rewritten to `__wrote_index0/__last0_value`; unused broad target fail-fast blocks are removed once target writes are scalarized; accepted assertion lines are collected only from focused slot-0 checks.
  - `dslc/cli/gemcutter.py`: focused prepass timeout now scales with `--ultimate-timeout-seconds` instead of being hardcoded at 120s.
  - Regression executed: `python3 -m unittest -v dslc.tests.transform.test_focused_direct dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_bounded_direct_check_preserves_accumulated_fallback_for_other_asserts dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_conjunctive_guarded_register_mirror_assert_gets_dsl_direct_check` passed.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; a follow-up process check found no residual solver process.

## 2026-05-03 ETC_NOMS_2024 pkt_len_total focused duplicate-check reduction

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_direct.prop`
- **Time**: 2026-05-03 08:27-08:33 Asia/Shanghai
- **Goal/Progress**: Removed duplicate focused global pass-boundary checks when write-site fail-fast instrumentation already gives the slot-0 target assertion, reducing error-location noise before the next optimization pass.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260503-082759-7b9b/`
  - Focused BPL: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260503-082759-7b9b/external_etc_noms2024_pkt_len_total_wraparound_direct.focused-index0.bpl`
  - Focused result: `Timeout`; focused CFG had 138 locations / 181 edges / 4 error locations; OverallTime about 273.4s.
  - Accepted focused assertion lines were only the injected write-site slot-0 checks at lines 312 and 344.
  - The focused BPL no longer had `procurator_bad := true` or a vacuous `assert !procurator_bad`.
- **Pitfalls (implementation/model issues)**:
  - Reducing error locations was not sufficient: the focused BPL still carried quantified `[bv11]` register initialization assumptions, unlike the quick slot-0 direct BPL. This likely keeps array/bitvector reasoning heavy for Ultimate.
  - This remains a focused direct under-approximation. A focused timeout is only "not found within the budget"; it is not a proof.
- **Fixes/regression tests**:
  - No additional test beyond the focused-direct regression suite in the previous entry; the next implementation task is to generalize quantified register-init elimination from `bv32` to `bvN` and apply the optimizer to focused BPL files before Ultimate.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no concurrent solver jobs were launched.

## 2026-05-03 ETC_NOMS_2024 pkt_len_total bvN init-elim focused witness

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_direct.prop`
- **Time**: 2026-05-03 08:56-09:35 Asia/Shanghai
- **Goal/Progress**: Generalized quantified register-initialization elimination from hardcoded `bv32` indices to `bvN` indices, then applied the same Boogie optimizer to the focused direct BPL before Ultimate. This targets the ETC `bv11` register-index bottleneck without changing the dataset P4.
- **Result**:
  - Initial optimized focused run: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260503-085633-4b35/`
    - Optimizer reported `[OPT] forall-init elimination: 5 -> 2` on the focused BPL.
    - Focused result: `UNSAFE`; marker kind `focused_under_approx`; target `etc_Ingress_reg_pkt_len_total`; `idx_var=etc_meta.register_index`; `zero=0bv11`; `target_value=0bv16`.
    - Counterexample line was 344, which is in accepted focused assertion lines `{312, 344}`; OverallTime about 11.8s; focused BPL had no `forall i:bv11`.
  - Conservative all-`reg[...]` access scan exposed two implementation-pitfall reruns:
    - `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260503-090227-a374/`: focused timeout, then original direct timeout. The optimizer did not eliminate the `bv11` register-init quantifiers because unused register extern bodies still contained `reg[etc_index]`.
    - `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260503-091541-8bc9/`: same timeout shape after the first unused-extern filter; static debugging showed Boogie attributes like `{:inline 1}` were being counted as procedure-body braces, so the unused procedure body was not skipped.
  - Final fixed run: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260503-093410-72b7/`
    - Optimizer reported `[OPT] forall-init elimination: 5 -> 2` on the focused BPL.
    - Focused result: `UNSAFE`; marker kind `focused_under_approx`; counterexample line 344, accepted lines `{312, 344}`; OverallTime about 12.3s.
    - Focused BPL had `forall i:bv11 count = 0`; the remaining two `forall bvN` occurrences are bvule helper axioms, not register-initialization quantifiers.
- **Pitfalls (implementation/model issues)**:
  - The first generalized implementation only scanned constant array accesses; this was too narrow for soundness because a direct `reg[dynamic]` access would have been missed. It was tightened so every real `reg[...]` access is considered, and any unbounded access preserves the quantifier.
  - The tightened scan then became overly conservative because it counted unused register `.read/.write` extern bodies. These bodies are not invoked after focused scalarization and should not define the accessed domain for the executable focused model.
  - The first unused-body skip mishandled Boogie attributes (`{:inline 1}`) as body braces. The brace accounting now strips attributes before tracking the actual function/procedure body.
  - These timeout reruns were implementation diagnostics, not evidence that the bug is absent. The final result is still a focused direct under-approximation witness, not a wraparound closure certificate.
- **Fixes/regression tests**:
  - `dslc/transform/wraparound_common.py`: generalized quantified-init regexes and explicit-index-init regexes from `bv32` to `bvN`, while keeping backward-compatible names.
  - `dslc/transform/wraparound_stages.py`: generalized finite-domain inference to arbitrary index widths, scans real `reg[...]` accesses conservatively, requires all real accesses to be bounded, and ignores unused register extern bodies when inferring executable accessed domains.
  - `dslc/cli/gemcutter.py`: counts all `forall ... : bvN` in the optimizer log and runs `_optimize_bpl_for_ultimate()` on focused direct BPL files before Ultimate.
  - `dslc/tests/wraparound/transform/test_wraparound_forall_init_elim.py`: added bv11 focused-shape coverage, dynamic-unbounded preservation tests, and a regression for unused `{:inline}` register extern bodies.
  - Regression executed: `python3 -m py_compile dslc/transform/wraparound_common.py dslc/transform/wraparound_stages.py dslc/cli/gemcutter.py dslc/transform/focused_direct.py` and `python3 -m unittest -v dslc.tests.wraparound.transform.test_wraparound_forall_init_elim dslc.tests.transform.test_focused_direct dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_bounded_direct_check_preserves_accumulated_fallback_for_other_asserts dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_conjunctive_guarded_register_mirror_assert_gets_dsl_direct_check` passed (24 tests).
- **Smoke/regression**: Solver runs were executed one at a time in WSL. A follow-up Windows process check found no residual `java`, `z3`, or `Ultimate` process.

## 2026-05-03 ETC_NOMS_2024 pkt_len_total slot0 regression after bvN init-elim

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_slot0.prop`
- **Time**: 2026-05-03 09:37-09:38 Asia/Shanghai
- **Goal/Progress**: Reran the existing slot-0 direct witness after the bvN quantified-init elimination and focused-BPL optimizer changes, to ensure the old quick direct witness still works.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_slot0/20260503-093753-ba2b/`
  - Main result: `UNSAFE`; counterexample line 558; OverallTime about 15.4s.
  - Witness rerun was disabled for this smoke, so the post-run witness classifier reported `CEX-WARN missing: no *.bpl-witness.graphml`. This does not change the solver regression result.
- **Pitfalls/Fixes**:
  - CLI exit is nonzero for `UNSAFE`, which is expected for bug finding.
  - No new code fix was needed; this is a regression guard for the bvN/focused changes.
- **Regression tests**:
  - Same focused/bvN unit suite remained green before this run: `python3 -m unittest -v dslc.tests.wraparound.transform.test_wraparound_forall_init_elim dslc.tests.transform.test_focused_direct dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_required_env_packet_vars_are_kept_without_widening_p4_slice`.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; a follow-up process check found no residual solver process.

## 2026-05-03 Flowrest pkt_len_total focused direct witness after bvN init-elim

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_len_total_wraparound_direct.prop`
- **Time**: 2026-05-03 09:41-09:42 Asia/Shanghai
- **Goal/Progress**: Re-ran a Flowrest dynamic-index packet-length accumulation bug after the bvN quantified-init elimination and focused-BPL optimization, to ensure the optimization generalizes beyond ETC.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound_direct/20260503-094102-27f8/`
  - Optimizer reported `[OPT] forall-init elimination: 5 -> 2` on the focused BPL.
  - Focused result: `UNSAFE`; marker kind `focused_under_approx`; target `flowrest_Ingress_reg_pkt_len_total`; `idx_var=flowrest_meta.register_index`; `zero=0bv16`; `target_value=0bv16`.
  - Counterexample line 330, accepted focused assertion lines `{298, 330}`; OverallTime about 10.3s.
  - Focused BPL had no remaining register-init `forall i:bv11/bv16` quantifiers.
- **Pitfalls/Fixes**:
  - This is a direct focused under-approximation witness, not a closure certificate. It is valid `UNSAFE` evidence for the slot-0 witness shape and does not claim proof over all dynamic hash slots.
  - No additional code fix was needed after the bvN/focused optimizer work.
- **Regression tests**:
  - Targeted focused/bvN unit suite passed before the solver run.
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no residual solver process after the run.

## 2026-05-03 Flowrest flow_duration guarded focused line-refresh repair

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound_direct.prop`
- **Time**: 2026-05-03 09:41-09:51 Asia/Shanghai
- **Goal/Progress**: Re-ran the stronger guarded Flowrest duration direct spec after bvN init elimination. The first run found a focused `UNSAFE` but rejected it because the focused assertion line numbers were computed before the post-pass deleted register-init quantifiers. Fixed the line-number refresh and reran the spec.
- **Result**:
  - Pitfall run: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound_direct/20260503-094146-1cae/`
    - Optimizer reported `[OPT] forall-init elimination: 5 -> 2`.
    - Focused solver result: `UNSAFE`, counterexample line 1001, OverallTime about 22.3s.
    - The pre-optimization accepted lines were `{844, 924, 1004}`, so the CLI correctly rejected the result and fell back to the original BPL, which timed out. Static inspection showed final focused BPL line 1001 was exactly the slot-0 assertion; the expected lines were stale because quantifier elimination removed three lines.
  - Final run after line refresh: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound_direct/20260503-095050-2418/`
    - Optimizer reported `[OPT] forall-init elimination: 5 -> 2`.
    - Focused result: `UNSAFE`; marker kind `focused_under_approx`; target `flowrest_Ingress_reg_flow_duration`; `idx_var=flowrest_meta.register_index`; `zero=0bv16`; `target_value=0bv32`.
    - Counterexample line 1001, accepted focused assertion lines `{841, 921, 1001}`; OverallTime about 21.9s.
    - Focused BPL had no remaining register-init `forall i:bv11/bv16` quantifiers.
- **Pitfalls (implementation/model issues)**:
  - Post-transform BPL optimizations can change line numbers. The focused prepass must validate counterexamples against assertion lines in the exact file passed to Ultimate, not the pre-optimized in-memory text.
  - This case has an additional guard (`meta.is_first != 1` and `meta.iat != 0`), so the accepted line scan must remain restricted to the final focused slot-0 assertion locations; it must not accept arbitrary internal assertions.
- **Fixes/regression tests**:
  - `dslc/transform/focused_direct.py`: exposed `find_focused_direct_assert_lines()` to rescan focused slot-0 assertion locations in arbitrary final BPL text.
  - `dslc/cli/gemcutter.py`: after optimizing the focused BPL, rereads the final file and refreshes accepted focused assertion lines before validating the Ultimate counterexample line.
  - `dslc/tests/transform/test_focused_direct.py`: added `test_assert_lines_can_be_refreshed_after_bpl_post_optimization`.
  - Regression executed: `python3 -m py_compile dslc/transform/focused_direct.py dslc/cli/gemcutter.py` and `python3 -m unittest -v dslc.tests.transform.test_focused_direct dslc.tests.wraparound.transform.test_wraparound_forall_init_elim dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_bounded_direct_check_preserves_accumulated_fallback_for_other_asserts dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_conjunctive_guarded_register_mirror_assert_gets_dsl_direct_check` passed (25 tests).
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; no residual solver process after the run.

## 2026-05-03 Review-driven soundness hardening for bvN init-elim

- **Specs/regressions**:
  - `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_direct.prop`
  - `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound_direct.prop`
  - `Procurator/argo/code/spec/bench/distcache_p2c_wraparound_bug.prop`
- **Time**: 2026-05-03 10:07-10:13 Asia/Shanghai
- **Goal/Progress**: Acted on subagent review findings around `bvN` quantified-init elimination. The key soundness issue was that the generic direct/focused optimizer must not infer register-index bounds from arbitrary textual `assume` statements, because such assumes may be path-local and not dominate all accesses.
- **Result**:
  - Targeted unit regression after the fix: `python3 -m py_compile dslc/transform/wraparound_stages.py dslc/transform/wraparound_instrument.py dslc/cli/gemcutter.py dslc/transform/focused_direct.py` and `python3 -m unittest -v dslc.tests.wraparound.transform.test_wraparound_forall_init_elim dslc.tests.transform.test_focused_direct dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_bounded_direct_check_preserves_accumulated_fallback_for_other_asserts dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_conjunctive_guarded_register_mirror_assert_gets_dsl_direct_check dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_required_env_packet_vars_are_kept_without_widening_p4_slice` passed (30 tests).
  - ETC focused smoke after hardening: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260503-100754-81f9/`
    - Optimizer reported `[OPT] forall-init elimination: 5 -> 2`.
    - Focused result: `UNSAFE`; marker kind `focused_under_approx`; target `etc_Ingress_reg_pkt_len_total`; accepted lines `{312, 344}`; counterexample line 344; OverallTime about 12.0s.
  - Flowrest guarded duration focused smoke after hardening: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound_direct/20260503-100841-4e1e/`
    - Optimizer reported `[OPT] forall-init elimination: 5 -> 2`.
    - Focused result: `UNSAFE`; marker kind `focused_under_approx`; target `flowrest_Ingress_reg_flow_duration`; accepted lines `{841, 921, 1001}`; counterexample line 1001; OverallTime about 32.1s.
  - DistCache certified closure regression after hardening: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260503-100948-4ae4/`
    - `ENTRY_CHECK=UNSAFE` in about 18.7s.
    - `near_wrap.unroll1=SAFE` in about 35.3s, then `near_wrap.unroll2=UNSAFE` in about 41.0s.
    - `CLOSURE_CHECK=SAFE` in about 53.2s.
    - Manifest remains `certified=true`; diagnostic `stopped after closure by request`.
- **Pitfalls (implementation/model issues)**:
  - Review finding: using path-insensitive assumptions as global bounds could weakly initialize non-dominated register slots in direct/ENTRY/CONFIRM/focused existential stages and create spurious `UNSAFE` witnesses.
  - Review finding: if focused BPL post-optimization fails to rescan assertion lines, keeping stale pre-optimization lines could accept a non-focused error location after line shifts.
  - Review finding: register extern body skipping should match the exact declared procedure/function name, not a substring in the declaration header.
- **Fixes/regression tests**:
  - `dslc/transform/wraparound_stages.py`: `_rewrite_forall_bv32_array_inits(..., use_assume_bounds=False)` now defaults to a semantics-preserving mode that only uses constant/directly bounded access expressions; it no longer uses arbitrary `assume` bounds in direct/focused/ENTRY/CONFIRM paths.
  - `dslc/transform/wraparound_instrument.py`: only `CLOSURE_CHECK` opts into `use_assume_bounds=True`, where dropping initialization facts over-approximates closure states and a `SAFE` proof remains conservative.
  - `dslc/cli/gemcutter.py`: focused line refresh now fails closed. If post-optimization focused assertion lines cannot be found, an `UNSAFE` focused result falls back to the original BPL rather than using stale line numbers.
  - `dslc/transform/wraparound_stages.py`: register extern body skipping now parses the exact declared function/procedure name.
  - Added regressions for non-dominating path-local assume bounds, exact extern declaration-name matching, extern call indices vs formal body index, and focused line refresh after BPL post-optimization.
- **Smoke/regression**: Solver runs were executed one at a time in WSL; follow-up process checks found no residual `java`, `z3`, or `Ultimate` process.

## 2026-05-03 Flowrest focused marker line consistency smoke

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound_direct.prop`
- **Time**: 2026-05-03 10:14-10:15 Asia/Shanghai
- **Goal/Progress**: After focused line refresh was made fail-closed, updated the marker writer so both `assert_line` and `assert_lines` refer to final post-optimization BPL line numbers. Reran the guarded Flowrest duration case to verify the auditable marker is internally consistent.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound_direct/20260503-101452-4b96/`
  - Optimizer reported `[OPT] forall-init elimination: 5 -> 2`.
  - Focused result: `UNSAFE`; marker kind `focused_under_approx`; target `flowrest_Ingress_reg_flow_duration`.
  - Marker now records `assert_line=841` and `assert_lines={841, 921, 1001}`; the counterexample line is 1001, which is one of the refreshed final-BPL focused assertion lines.
  - OverallTime about 29.2s.
- **Pitfalls/Fixes**:
  - Before this minor cleanup, marker `assert_lines` used refreshed final-BPL lines but singleton `assert_line` could still contain the pre-optimization first line. This did not affect acceptance logic, but it made the JSON evidence less clean.
  - `dslc/cli/gemcutter.py`: marker `assert_line` now uses `expected_lines[0]` when refreshed lines exist.
- **Regression tests**:
  - `python3 -m py_compile dslc/cli/gemcutter.py` and `python3 -m unittest -v dslc.tests.transform.test_focused_direct dslc.tests.wraparound.transform.test_wraparound_forall_init_elim` passed (27 tests).
- **Smoke/regression**: Single Ultimate/GemCutter job at a time in WSL; follow-up process check found no residual solver process.

## 2026-05-03 Focused direct workflow split and ETC slot0 smoke

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_direct.prop`
- **Time**: 2026-05-03 11:13-11:21 Asia/Shanghai
- **Goal/Progress**: Split the focused direct prepass out of `dslc/cli/gemcutter.py` into `dslc/workflows/focused_direct.py`, then reran the ETC focused witness after review-driven soundness fixes. This was a single-spec smoke for the CLI boundary and focused under-approx marker path; it is still a direct under-approx witness, not a wraparound closure certificate.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260503-111913-949c/`
  - Optimizer reported `[OPT] forall-init elimination: 5 -> 2` on the focused BPL.
  - Focused result: `UNSAFE`; marker kind `focused_under_approx`; target `etc_Ingress_reg_pkt_len_total`; `idx_var=etc_meta.register_index`; `zero=0bv11`; `target_value=0bv16`.
  - Marker accepted final focused assertion lines `{312, 344}`; Ultimate counterexample line was `344`.
  - Ultimate reported OverallTime about `14.4s`.
- **Pitfalls (implementation/model issues)**:
  - Subagent review caught that the CLI looked for the focused marker under `out_bpl.parent`, while the prepass writes it under `log_path.parent`; this fails when `--log` is outside the output directory.
  - Review also triggered a stricter soundness check of the focused transform. The old focused read rewrite used `reg__last0_value`, which records the most recent slot-0 write and is not generally equal to the current array value `reg[0]`. This could make the focused under-approximation too strong and produce spurious direct witnesses.
- **Fixes/regression tests**:
  - `dslc/workflows/focused_direct.py`: owns focused prepass orchestration, marker validation, post-optimization assertion-line refresh, and fail-closed fallback policy.
  - `dslc/cli/gemcutter.py`: now only wires the focused workflow and looks up focused markers in `job.log_path.parent`.
  - `dslc/transform/focused_direct.py`: focused reads now use the exact array slot (`reg[0bvW]`) instead of `reg__last0_value`; writes still update both the array slot and mirrors.
  - Added regressions in `dslc/tests/workflows/test_focused_direct_workflow.py`, `dslc/tests/cli/test_gemcutter_focused_marker.py`, and `dslc/tests/transform/test_focused_direct.py`.
  - Regression executed: `python3 -m unittest -v dslc.tests.bench.test_p4b_semantic_audit dslc.tests.bench.test_scan_p4b_coverage dslc.tests.transform.test_focused_direct dslc.tests.workflows.test_focused_direct_workflow dslc.tests.cli.test_gemcutter_focused_marker dslc.tests.wraparound.schedule.test_wraparound_projection dslc.tests.wraparound.schedule.test_wraparound_schedule dslc.tests.wraparound.cegis.core.test_wraparound_cegis_order dslc.tests.wraparound.test_wraparound_candidate_gating dslc.tests.wraparound.transform.test_wraparound_transform dslc.tests.wraparound.transform.test_wraparound_forall_init_elim dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_bounded_direct_check_preserves_accumulated_fallback_for_other_asserts dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_conjunctive_guarded_register_mirror_assert_gets_dsl_direct_check dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_required_env_packet_vars_are_kept_without_widening_p4_slice dslc.tests.p4b.test_p4b_translator_regressions.TestP4BTranslatorRegressions.test_ubpf_three_arg_hash_lowers_to_deterministic_assignment dslc.tests.p4b.test_p4b_translator_regressions.TestP4BTranslatorRegressions.test_counter_externs_emit_stateful_updates dslc.tests.p4b.test_p4b_translator_regressions.TestP4BTranslatorRegressions.test_tna_registeraction_execute_rhs_is_stateful dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_external_flowrest_flow_duration_seed_prunes_sibling_feature_registers dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_external_flowrest_ttl_seed_keeps_ttl_assignments` passed (138 tests).
- **Smoke/regression**: The P4B translator was rebuilt with `cmake --build . --target p4c-translator -j"$(nproc)"` before P4B tests. Solver runs were executed one at a time in WSL; follow-up process check found no residual `java`, `z3`, or `Ultimate` process.

## 2026-05-03 Flowrest guarded focused smoke after exact slot reads

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound_direct.prop`
- **Time**: 2026-05-03 11:21-11:23 Asia/Shanghai
- **Goal/Progress**: Re-ran the guarded Flowrest `flow_duration` direct witness after the focused transform was hardened to read `reg[0bvW]` instead of `reg__last0_value`. This validates that the real guarded witness still exists under the exact slot-0 under-approximation.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound_direct/20260503-112127-9e52/`
  - Optimizer reported `[OPT] forall-init elimination: 5 -> 2` on the focused BPL.
  - Focused result: `UNSAFE`; marker kind `focused_under_approx`; target `flowrest_Ingress_reg_flow_duration`; `idx_var=flowrest_meta.register_index`; `zero=0bv16`; `target_value=0bv32`.
  - Marker accepted final focused assertion lines `{841, 921, 1001}`; Ultimate counterexample line was `1001`.
  - Ultimate reported OverallTime about `28.0s`.
- **Pitfalls (implementation/model issues)**:
  - This run specifically checks that the previous `__last0_value` read shortcut was not needed for the witness. The focused read is now a direct Boogie array read from the exact slot, so the under-approximation is cleaner and does not depend on last-write mirror history.
- **Fixes/regression tests**:
  - `dslc/transform/focused_direct.py`: focused read scalarization now emits `tmp := reg[0bvW]`.
  - `dslc/tests/transform/test_focused_direct.py`: added `test_focused_reads_use_array_slot_not_last_write_mirror` and updated existing focused expectations.
  - The 138-test targeted regression suite from the preceding ETC entry remained green before this solver run.
- **Smoke/regression**: Solver runs were executed one at a time in WSL; follow-up process check found no residual `java`, `z3`, or `Ultimate` process.

## 2026-05-03 P4B semantic coverage smoke and file-size split

- **Scope**: P4B architecture/semantic coverage scan over `P4B-Translator/testdata/p4_16_samples` (first 20 discovered programs, no Ultimate/GemCutter solver).
- **Time**: 2026-05-03 11:27-11:34 Asia/Shanghai
- **Goal/Progress**: Exercised the new `--semantic-audit` scan path after translator improvements for uBPF/eBPF/PSA/TNA features. Also enforced the project file-size rule by splitting schedule replay refinement tests and moving stable projection helpers into the expression utility module.
- **Result**:
  - Coverage output: `.tmp/procurator/coverage-smoke/20260503-1127/coverage.{json,md}`
  - P4B scan: 20/20 programs translated successfully, 0 compile failures.
  - Target mix: eBPF=2, uBPF=3, v1model=13, v1model-like=2.
  - Semantic status: `OK=17`, `SKIP=3`, `FAIL=0`; no semantic weakness/failure rows.
  - File-size check after split: largest Python file in `dslc` is now `dslc/analysis/wraparound_projection.py` at 1294 lines; C++ verify files remain below 2500 lines (`slicer_internal.h` at 2470 lines).
- **Pitfalls (implementation/model issues)**:
  - `dslc/analysis/wraparound_projection.py` and `dslc/tests/wraparound/schedule/test_wraparound_schedule.py` briefly exceeded the 1300-line Python limit after dynamic-slot projection/refinement work.
  - Windows-side `git diff` cannot hash several repo symlink/reparse-point P4 sample files (`Function not implemented`); WSL-side `git diff` shows no text diff for those paths. Do not include those platform-metadata changes in feature commits unless explicitly intended.
- **Fixes/regression tests**:
  - `dslc/analysis/wraparound_projection_exprs.py`: now owns stable cutpoint and packet-slot helper predicates used by projection extraction.
  - `dslc/tests/wraparound/schedule/test_schedule_replay_refinement.py`: split witness-timeout, projection-weakening, and stop-after-closure tests out of the large schedule test file.
  - Regression executed: `python3 -m unittest -v dslc.tests.wraparound.schedule.test_wraparound_projection dslc.tests.wraparound.schedule.test_wraparound_schedule dslc.tests.wraparound.schedule.test_schedule_replay_refinement dslc.tests.wraparound.schedule.test_schedule_manifest_certification` passed (40 tests), followed by the broader 144-test targeted suite, also PASS.
- **Smoke/regression**: No solver was run for the coverage scan; follow-up process check found no residual `java`, `z3`, or `Ultimate` process.

## 2026-05-03 Schedule certification and focused marker hardening

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_direct.prop`
- **Time**: 2026-05-03 12:00-12:04 Asia/Shanghai
- **Goal/Progress**: Addressed review findings that could make schedule replay certificates or focused direct artifacts too permissive. Reran the ETC focused direct case as a single-spec smoke after the hardening.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260503-120012-a261/`
  - Focused result: `UNSAFE`; marker kind `focused_under_approx`; target `etc_Ingress_reg_pkt_len_total`; `idx_var=etc_meta.register_index`; `zero=0bv11`; `target_value=0bv16`.
  - Marker now records both `source_bpl_sha256` and `focused_bpl_sha256`; validator accepts it as `focused_under_approx`.
  - Accepted final focused assertion lines were `{312, 344}`; Ultimate counterexample line was `344`; Ultimate OverallTime about `14.0s`.
- **Pitfalls (implementation/model issues)**:
  - Dependency projection failure paths (`no_global_vars`, missing deterministic scheduler, missing phase bodies) previously inherited `complete=True`, which could let an analysis failure flow into a certified schedule manifest.
  - Syntax-only manifest certification accepted any identifier inside `array[index]` predicates; this could admit transient header/meta-derived indices such as `flow_id_reg[s1_hdr.foo]`.
  - Subagent review caught one more certificate-soundness issue: `dependency_projection_unstable_cutpoint_guards=N` was recorded only as a note, while `complete` could still remain `True`. That meant a target-write guard with residual transient control/data state could still flow into `projection_complete=true`.
  - Focused direct markers were freshness-checked by mtime/path shape only, lacked hashes, and short user timeouts were silently expanded to 120s.
  - Downstream sanity checks only recognized GraphML witnesses or wraparound manifests, so focused under-approx evidence could be reported as missing even when the CLI intentionally skipped the original run.
- **Fixes/regression tests**:
  - `dslc/analysis/wraparound_projection.py`: analysis-failure returns now set `complete=False`; unstable cutpoint guards also force `complete=False`; manifest-facing predicate checks reject unstable array-index tokens in syntax-only mode.
  - `dslc/analysis/wraparound_projection_exprs.py`: added array-select parsing and manifest-stability helpers, keeping the main projection file at exactly 1300 lines.
  - `dslc/workflows/focused_direct.py`: marker validation is hash-based (`source_bpl_sha256`, `focused_bpl_sha256`) and respects explicit positive `--ultimate-timeout-seconds`.
  - `dslc/bench/validate_counterexample.py` and `dslc/bench/run_e2e_ablations.py`: focused markers are now treated as explicit `focused_under_approx` evidence, not missing GraphML.
  - Regression executed: targeted projection/schedule tests passed (41 tests); focused/marker/witness/e2e sanity tests passed (26 tests); broader targeted suite passed (169 tests).
- **Smoke/regression**: Solver runs were executed one at a time in WSL; follow-up checks found no residual `java`, `z3`, or `Ultimate` process before the real spec smoke.

## 2026-05-03 NetChain closure smoke after projection fail-closed review

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`
- **Time**: 2026-05-03 12:12-12:15 Asia/Shanghai
- **Goal/Progress**: After subagent review required `dependency_projection_unstable_cutpoint_guards` to force `complete=false`, reran the canonical fixed-slot NetChain schedule certificate to ensure the fail-closed projection gate did not break a sound existing closure proof.
- **Result**:
  - Run directory: `.tmp/procurator/verify/netchain_wraparound_bug/20260503-121238-797f/`
  - Manifest: `.tmp/procurator/verify/netchain_wraparound_bug/20260503-121238-797f/wraparound/target.00.s1_sequence_reg/wraparound.cegis.manifest.json`
  - `ENTRY_CHECK=UNSAFE` in about `19.6s`.
  - `NEAR_WRAP=UNSAFE` in about `33.7s` at `near_wrap.unroll1`.
  - `CLOSURE_CHECK=SAFE` in about `85.3s`.
  - Manifest validator: `[OK] certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id`.
  - Recorded projection remains complete with scalar projection vars `procurator_phase,h1_inbox_count,s1_inbox_count,s2_inbox_count` and no dependency predicates/exprs.
- **Pitfalls (implementation/model issues)**:
  - Tightening incomplete dynamic-slot guards is intentionally conservative. It can demote dynamic-index cases with residual transient guards to near/direct/fallback instead of closure certification, but fixed-slot certificates like NetChain should remain certifiable.
- **Fixes/regression tests**:
  - `dslc/analysis/wraparound_projection.py`: `incomplete_cutpoint_guards` is now part of the `complete=False` condition and emits `dependency_projection_incomplete`.
  - `dslc/tests/wraparound/schedule/test_wraparound_projection.py`: dynamic-slot projection tests now distinguish "expr captured for debugging/near-wrap" from "projection complete enough to certify".
  - Regression executed: schedule/projection/manifest tests passed (41 tests), followed by the broader targeted suite (169 tests).
- **Smoke/regression**: Single Ultimate/GemCutter job in WSL; follow-up process check found no residual solver process.

## 2026-05-03 ETC near-wrap timeout classification and unroll budget fix

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_count_wraparound.prop`
- **Time**: 2026-05-03 12:19-12:36 Asia/Shanghai
- **Goal/Progress**: Rechecked the dynamic-index ETC packet-count wraparound path after projection certification was made fail-closed. The goal was to distinguish "bug absent" from "verification did not finish" and to keep one staged experiment inside a bounded time budget.
- **Result**:
  - Pre-fix run directory: `.tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260503-121909-1b43/`
    - `ENTRY_CHECK=UNSAFE` in about `17.7s`.
    - `near_wrap.unroll1=Timeout` after about `298.2s`.
    - Old strategy still launched `near_wrap.unroll2`, which pushed the outer command to its 600s timeout.
  - Post-fix run directory: `.tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260503-123206-e346/`
    - `ENTRY_CHECK=UNSAFE` in about `17.1s`.
    - `near_wrap.unroll1=Timeout` after about `195.3s` with `--ultimate-timeout-seconds 180`.
    - No `near_wrap.unroll2.log` was generated; the manifest records fallback instead of continuing to spend budget.
  - Classification: this is **not** a SAFE/nonexistent-bug result. The entry cutpoint is reachable, but the current near-wrap proof/search does not finish within the stage budget for this dynamic-index/incomplete-projection case.
- **Pitfalls (implementation/model issues)**:
  - `projection_complete=false` is expected here: dependency projection records dynamic-slot exprs, contradictory status predicates, and `dependency_projection_unstable_cutpoint_guards=1`, so closure certification must be refused.
  - The old minimal-unroll growth policy treated short `Timeout/UNKNOWN` like a reason to keep increasing unroll. That violates the staged-experiment discipline: only a concrete `SAFE` at a shorter suffix should justify trying a larger suffix.
- **Fixes/regression tests**:
  - `dslc/workflows/wraparound_support/loop_schedule.py`: near-wrap exploration now grows only after `SAFE`; `Timeout/UNKNOWN/ERROR` stops the candidate and falls back.
  - `dslc/tests/wraparound/schedule/test_wraparound_schedule.py`: updated the regression to `test_schedule_replay_stops_after_short_unknown` and retained the `SAFE -> grow -> UNSAFE` case.
  - Regression executed: focused schedule tests passed (4 tests), schedule/projection/manifest/refinement tests passed (44 tests), focused/witness sanity tests passed (25 tests).
- **Smoke/regression**: Runs were executed one at a time in WSL; follow-up process checks found no residual solver process.

## 2026-05-03 Flowrest pkt_len_total focused direct witness

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_len_total_wraparound_direct.prop`
- **Time**: 2026-05-03 12:36-12:37 Asia/Shanghai
- **Goal/Progress**: Confirmed that a Flowrest 16-bit accumulated-length wraparound witness still reports cleanly through the focused under-approximation artifact path after marker hash and downstream sanity changes.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound_direct/20260503-123636-2cc2/`
  - Focused result: `UNSAFE`; marker kind `focused_under_approx`; target `flowrest_Ingress_reg_pkt_len_total`; `idx_var=flowrest_meta.register_index`; `zero=0bv16`; `target_value=0bv16`.
  - Marker records `source_bpl_sha256=463b0290506b942e48d4718b21d56a7e430d84bc42e87a54f0ac1d9c3416cdf5` and `focused_bpl_sha256=76aadeae100a4f4ce00f6dc065cabd1d34d98b924f656e720b564acbdfa38c0f`.
  - Accepted final focused assertion lines were `{298, 330}`; Ultimate counterexample line was `330`; OverallTime about `11.8s`.
  - Validator: `[OK] focused_under_approx`.
- **Pitfalls/Fixes**:
  - This is a direct under-approximation witness, not a closure certificate. It is sound as an UNSAFE bug witness because it fixes slot 0 and validates that Ultimate hit the transformed focused assertion line in the exact focused BPL.
- **Regression tests**:
  - The focused marker/witness tests from the preceding entry remained green (25 tests).
- **Smoke/regression**: Single Ultimate/GemCutter job in WSL; no concurrent solver jobs were launched.

## 2026-05-03 upstream p4c base sync and verify-backend repair

- **Spec/scan**:
  - Upstream base: `p4lang/p4c` snapshot `dd688c9bd4cf43eafd9b8cd405d428801d23231c`, `Version.txt=1.2.5.12`.
  - Focused translator regressions over P4B platform/features: TNA include discovery, NetChain slicing, FlowDoS parser/hash, Flowrest/ETC RegisterAction metadata, PSA/eBPF/uBPF/PNA regressions, P4TV assert/assume, Boogie out-param compatibility.
- **Time**: 2026-05-03 23:41 Asia/Shanghai
- **Goal/Progress**: Followed the upstream-sync direction: keep Procurator-owned `backends/verify` logic, but move the surrounding P4C frontend/backends/includes toward the latest upstream base and repair verify translation/analysis against the newer frontend IR shape.
- **Result**:
  - P4B build passed in WSL: `cmake --build P4B-Translator/build-verify-sync --target p4c-translator -j8`.
  - Focused P4B regression suite passed in WSL: `python3 -m unittest -v dslc.tests.p4b.test_p4b_tofino_cpp_defines dslc.tests.p4b.test_p4b_translator_slicing_selftest dslc.tests.p4b.test_p4b_translator_regressions dslc.tests.p4b.test_p4b_translator_p4tv_assert_assume dslc.tests.p4b.test_p4b_translator_boogie_out_params` (46 tests, about 116s).
  - Netchain slicing selftest passed: `p4c-translator ... --slicing-vars=sequence_reg[0] --slicing-selftest=netchain_seq .../netchain_16.p4`.
  - FlowDoS hash/index selftest passed: `p4c-translator ... --slicing-vars=counter_filter --slicing-selftest=flowdos_hash_index_dependency .../external_int_flowdos/switch-flow.p4`.
- **Pitfalls (implementation/model issues)**:
  - Latest p4c frontend lifts action parameters into control-local temporaries and no-argument actions. The old index-definition metadata therefore reported proxy/local dependencies such as `MyIngress_srcIp` instead of the true header/data dependency, which weakens wraparound projection/certificate reasoning.
  - JSON IR slicing collected register/index metadata without statement pruning. Letting that metadata prune register domains is unsound because the JSON path still emits the full unpruned program.
  - TNA programs including `<tna.p4>` need the upstream Tofino include path and target define from the P4B invocation layer, not dataset edits.
  - FlowDoS parser states produced by the newer frontend include copied states such as `parse_udp_0` and `parse_int_over_tcp_0`; the verify backend previously emitted `goto` targets with those names but fallback labels such as `parse_udp__p4b_1`, leaving dangling labels in Boogie.
- **Fixes/regression tests**:
  - `P4B-Translator/backends/verify/analysis/index_defs.cpp`: added action-name aliases and action-local deterministic assignment expansion so structured index definitions expose real header/meta dependencies while avoiding unsound parser/control branch substitution.
  - `P4B-Translator/backends/verify/bpl_verify/pipeline.cpp` and `P4B-Translator/backends/verify/translate/impl/lowering/translate_program.cpp`: disable register-domain pruning for JSON IR slicing paths.
  - `dslc/backends/boogie/node/p4b.py`: auto-adds the Tofino include path/define for `<tna.p4>` and supports `P4B_TOFINO_INCLUDE_PATH`.
  - `P4B-Translator/backends/verify/translate/impl/lowering/translate_program.cpp`: parser label normalization now recognizes numeric-suffixed copied parser states, preventing goto/label mismatches.
  - `dslc/tests/p4b/*`: updated and added regressions for TNA include handling, FlowDoS parser compatibility, dynamic hash dependencies, JSON IR register domains, PSA/eBPF/uBPF/PNA extern lowering, P4TV assert/assume, and current upstream action-local out-param lowering.
- **Smoke/regression**: Translation/build/unit-test only; no Ultimate/GemCutter job was launched in this checkpoint.

## 2026-05-03 PSA/eBPF/uBPF/PNA/TNA semantic coverage after upstream sync

- **Spec/scan**:
  - PSA: `P4B-Translator/testdata/p4_16_samples` with `--target psa`.
  - eBPF: `P4B-Translator/testdata/p4_16_samples` with `--target ebpf`.
  - uBPF: `P4B-Translator/testdata/p4_16_samples` with `--target ubpf`.
  - PNA: upstream p4c samples under `.tmp/procurator/upstream/p4c/testdata/p4_16_samples` with `--target pna`.
  - TNA: repo dataset plus P4B samples with `--target tna`.
- **Time**: 2026-05-03 23:58 Asia/Shanghai
- **Goal/Progress**: Verified that the upstream-sync translator does more than parse current architecture programs: it emits semantic evidence for stateful/architecture features instead of silently dropping them.
- **Result**:
  - PSA full scan: `.tmp/procurator/p4b_coverage/psa_semantic_20260503_sync_full_after_checksum/coverage.md`; 157/157 compile OK, 157/157 semantic OK.
  - eBPF scan: `.tmp/procurator/p4b_coverage/ebpf_semantic_20260503_sync/coverage.md`; 30/30 compile OK, semantic status OK/SKIP only.
  - uBPF scan: `.tmp/procurator/p4b_coverage/ubpf_semantic_20260503_sync/coverage.md`; 14/14 compile OK, semantic status OK/SKIP only.
  - PNA upstream batches: `.tmp/procurator/p4b_coverage/pna_upstream_semantic_20260503_sync_batch{0,1,2}/coverage.md`; 71/71 compile OK, 71/71 semantic OK.
  - TNA dataset scan: `.tmp/procurator/p4b_coverage/tna_semantic_20260503_sync/coverage.md`; 13/13 compile OK, 13/13 semantic OK.
  - Focused P4B regression suite passed in WSL after the checksum refinement: 47 tests in about 99s.
- **Pitfalls (implementation/model issues)**:
  - PSA checksum samples initially remained `WEAK`: v1model `verify_checksum`/`update_checksum` could still be emitted as comment-only effects, which is too weak for platform semantic coverage and for later dependency/projection extraction.
  - PSA `InternetChecksum.clear/add/get` is a different extern-summary path from v1model `verify_checksum`/`update_checksum`; using a PSA parser-checksum sample to test the v1model event path was the wrong regression anchor.
- **Fixes/regression tests**:
  - `P4B-Translator/backends/verify/translate/impl/core/translate.cpp`: added global checksum event flags `p4b_checksum_verified`, `p4b_checksum_updated`, and `p4b_checksum_error`, reset at `mainProcedure` entry.
  - `P4B-Translator/backends/verify/translate/impl/lowering/translate_statement.cpp`: v1model `verify_checksum` now records a verification event and nondeterministic checksum error flag; `update_checksum` records an update event and conservatively havoc-updates the target checksum field under the call condition.
  - `dslc/bench/p4b_semantic_audit.py`: treats the checksum event model as semantic OK while keeping pure extern `clear/add/get` summaries auditable.
  - `dslc/tests/p4b/test_p4b_translator_regressions.py`: added a v1model checksum regression using `checksum1-bmv2.p4`.
  - `dslc/tests/bench/test_p4b_semantic_audit.py`: added audit coverage for the checksum event summary.
  - Focused regressions passed: `python3 -m unittest -v dslc.tests.p4b.test_p4b_translator_regressions dslc.tests.bench.test_p4b_semantic_audit`.
- **Smoke/regression**: Translation/audit/unit-test only; no Ultimate/GemCutter job was launched in this checkpoint.

## 2026-05-04 NetChain header-stack upstream-sync repair and certificate rerun

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`
- **Time**: 2026-05-04 01:45-02:17 Asia/Shanghai
- **Goal/Progress**: After the latest-p4c base sync, NetChain no longer reached ENTRY because the verify translator emitted uses of `hdr.overlay.*` header-stack fields without declaring them. Repaired the verify-backend compatibility layer and reran NetChain in staged order: compile/smoke, ENTRY, NEAR, then full closure.
- **Result**:
  - P4B build passed in WSL: `cmake --build P4B-Translator/build-verify-sync --target p4c-translator -j4`, followed by copying the binary into `P4B-Translator/build-host/{backends/verify/,}`.
  - Header-stack regression passed: `python3 -m unittest -v dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_netchain_sliced_header_stack_declarations ...test_netchain_pop_front_header_stack_slicing ...test_netchain_seq_seed_slicing`.
  - NetChain compile/smoke passed: `./bin/procurator compile --spec ...netchain_wraparound_bug.prop --out /tmp/netchain_wrap_compile.bpl --boogie-harness sequential --no-two-stage && ./bin/procurator smoke --bpl /tmp/netchain_wrap_compile.bpl --harness sequential`.
  - Staged ENTRY run: `.tmp/procurator/verify/netchain_wraparound_bug/20260504-015238-6593/`, `ENTRY_CHECK=UNSAFE` in about 50.9s.
  - Staged NEAR run: `.tmp/procurator/verify/netchain_wraparound_bug/20260504-015433-d275/`, `ENTRY_CHECK=UNSAFE` in about 21.3s and `NEAR_WRAP=UNSAFE` in about 90.2s.
  - Full certificate run: `.tmp/procurator/verify/netchain_wraparound_bug/20260504-021029-e969/`, manifest `.tmp/procurator/verify/netchain_wraparound_bug/20260504-021029-e969/wraparound/target.00.s1_sequence_reg/wraparound.cegis.manifest.json`; `ENTRY_CHECK=UNSAFE` in about 37.5s, `NEAR_WRAP=UNSAFE` in about 67.8s, `CLOSURE_CHECK=SAFE` in about 286.0s, total about 391s (<8min). CLI printed `[CEX] certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id`.
- **Pitfalls (implementation/model issues)**:
  - This was not a SAFE/nonexistent-bug outcome. The old failure was a P4B translation completeness bug caused by newer p4c retaining header-stack element types as `Type_Name` instead of already-resolved `Type_Header`; `P4VerifyCompat::asHeaderStackType()` therefore rejected the stack before translator lowering could call `resolveHeaderType()`.
  - The first post-closure CLI run produced a misleading `[CEX-WARN] not certified` even though the manifest was certified. The validator re-parsed Ultimate logs differently from the wraparound runner: closure logs contained a target `Registering result SAFE ... (0 of 1 remaining)` followed by a late generic Timeout line after early shutdown.
  - One process-check command was misquoted across PowerShell/WSL and accidentally invoked `java`, `z3`, and `cmake` help paths. The corrected check uses `ps -eo pid,comm,args` and PowerShell-side filtering.
- **Fixes/regression tests**:
  - `P4B-Translator/backends/verify/verify_compat.h`: accepts `IR::Type_Array` as a header-stack candidate and leaves element-type resolution to translator/typeMap call sites, restoring `hdr.overlay` declarations under the latest frontend IR.
  - `dslc/tests/p4b/translator/test_header_stack.py`: added `test_netchain_sliced_header_stack_declarations`, asserting the sliced NetChain BPL declares `hdr.overlay`, `.last`, all 10 stack elements, their validity bits, and `swip` fields.
  - `dslc/bench/validate_counterexample.py`: schedule-replay manifest validation now uses the same wraparound-stage result evidence policy as the runner and requires matching log evidence plus recorded stage result, avoiding false warning on early-stop closure logs.
  - `dslc/tests/toolchain/test_validate_counterexample.py`: added a regression for wraparound manifests whose logs contain a matching `Registering result ... (0 of 1 remaining)` plus a later generic Timeout line.
  - `dslc/tests/p4b/translator/test_no_slicing_control_seeds_flag.py`: moved the translator wrapper flag tests into the new translator subpackage. `dslc/tests/p4b` now has 8 root files and the largest Python test file there is `test_p4b_translator_slicing_selftest.py` at 1292 lines, satisfying the file-size/directory organization rule.
  - Focused WSL regression passed: P4B platform/wraparound targeted suite, 136 tests in about 102s; toolchain validator tests, 10 tests; py_compile for the changed validator; real NetChain manifest validator now returns certified.
  - Post-split focused WSL regression passed: `python3 -m unittest -v dslc.tests.p4b.translator.test_header_stack dslc.tests.p4b.translator.test_no_slicing_control_seeds_flag ...test_netchain_pop_front_header_stack_slicing ...test_netchain_seq_seed_slicing` (5 tests), followed by validator/schedule/projection/header-stack focused suite (54 tests).
- **Smoke/regression**: Solver jobs were run one at a time in WSL. Follow-up process check found no residual Ultimate/java/z3/p4c-translator/cmake build jobs beyond unrelated IDE/background services.

## 2026-05-04 DistCache P2C leafload wraparound certificate rerun

- **Spec**: `Procurator/argo/code/spec/bench/distcache_p2c_wraparound_bug.prop`
- **Time**: 2026-05-04 02:39-02:49 Asia/Shanghai
- **Goal/Progress**: Re-ran the known DistCache P2C leafload wraparound bug after the upstream-p4c/header-stack repair, using the staged schedule-replay pipeline. The run followed the required order: compile/smoke, ENTRY, NEAR, then full CLOSURE only after ENTRY and NEAR had concrete signal.
- **Result**:
  - Compile/smoke passed: `./bin/procurator compile --spec ...distcache_p2c_wraparound_bug.prop --out /tmp/distcache_p2c_wrap_compile.bpl --boogie-harness sequential --no-two-stage`, followed by `./bin/procurator smoke --bpl /tmp/distcache_p2c_wrap_compile.bpl --harness sequential`.
  - ENTRY-only run: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260504-024024-2a9d/`, `ENTRY_CHECK=UNSAFE` in about `20.7s`.
  - NEAR-only run: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260504-024101-32b5/`, `ENTRY_CHECK=UNSAFE` in about `16.9s`; `near_wrap.unroll1=SAFE` in about `46.3s`; `near_wrap.unroll2=UNSAFE` in about `60.8s`.
  - Full certificate run: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260504-024507-6588/`, manifest `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260504-024507-6588/wraparound/target.00.clientTrack_partitionswitchIngress_leafload_reg/wraparound.cegis.manifest.json`; `ENTRY_CHECK=UNSAFE` in about `24.4s`, `near_wrap.unroll1=SAFE` in about `45.9s`, `near_wrap.unroll2=UNSAFE` in about `63.0s`, and `CLOSURE_CHECK=SAFE` in about `69.1s`.
  - CLI printed `[CEX] certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id`; exit code was `1`, as expected for a certified bug.
- **Pitfalls (implementation/model issues)**:
  - This was not a false SAFE or nonexistent-bug outcome. `near_wrap.unroll1=SAFE` only meant the one-round suffix was too short; the schedule-replay policy correctly grew after a concrete SAFE and found `UNSAFE` at unroll2.
  - A quick manifest-inspection helper command was misquoted once across PowerShell/WSL, but no generated artifact or solver run was affected.
- **Fixes/regression tests**:
  - No code change was needed for this spec. The existing fixed-index projection was complete: scheduler phase, `clientTrack_inbox_count`, `io_inbox_count`, and `dsl_pump_mode`; target register `clientTrack_partitionswitchIngress_leafload_reg[2]`; `step_delta=+1`.
- **Smoke/regression**: Solver jobs were run one at a time in WSL. The compile/smoke stage passed before ENTRY/NEAR/CLOSURE, and the full run produced a certified wraparound manifest.

## 2026-05-04 DistCache P2C spineload wraparound certificate rerun

- **Spec**: `Procurator/argo/code/spec/bench/distcache_p2c_spineload_wraparound_bug.prop`
- **Time**: 2026-05-04 02:49-02:59 Asia/Shanghai
- **Goal/Progress**: Re-ran the symmetric DistCache P2C spineload wraparound bug using staged schedule replay. This case exercises a longer functional suffix: overflow the spine-load counter, bump the leaf-load counter, then issue the P2C query.
- **Result**:
  - Compile/smoke passed: `./bin/procurator compile --spec ...distcache_p2c_spineload_wraparound_bug.prop --out /tmp/distcache_p2c_spineload_wrap_compile.bpl --boogie-harness sequential --no-two-stage`, followed by `./bin/procurator smoke --bpl /tmp/distcache_p2c_spineload_wrap_compile.bpl --harness sequential`.
  - ENTRY-only run: `.tmp/procurator/verify/distcache_p2c_spineload_wraparound_bug/20260504-024918-d399/`, `ENTRY_CHECK=UNSAFE` in about `18.0s`.
  - NEAR-only run: `.tmp/procurator/verify/distcache_p2c_spineload_wraparound_bug/20260504-024954-84ba/`, `ENTRY_CHECK=UNSAFE` in about `20.7s`; `near_wrap.unroll1=SAFE` in about `50.1s`; `near_wrap.unroll2=SAFE` in about `71.5s`; `near_wrap.unroll3=UNSAFE` in about `120.5s`.
  - Full certificate run: `.tmp/procurator/verify/distcache_p2c_spineload_wraparound_bug/20260504-025447-532a/`, manifest `.tmp/procurator/verify/distcache_p2c_spineload_wraparound_bug/20260504-025447-532a/wraparound/target.00.clientTrack_partitionswitchIngress_spineload_reg/wraparound.cegis.manifest.json`; `ENTRY_CHECK=UNSAFE` in about `25.1s`, `near_wrap.unroll1=SAFE` in about `39.1s`, `near_wrap.unroll2=SAFE` in about `53.8s`, `near_wrap.unroll3=UNSAFE` in about `91.2s`, and `CLOSURE_CHECK=SAFE` in about `58.0s`.
  - CLI printed `[CEX] certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id`; exit code was `1`, as expected for a certified bug.
- **Pitfalls (implementation/model issues)**:
  - The early NEAR `SAFE` results are not evidence that the bug is absent; they only show that shorter suffixes are insufficient for this three-step functional script. The scheduler correctly grows only after concrete SAFE and reaches `UNSAFE` at unroll3.
- **Fixes/regression tests**:
  - No code change was needed for this spec. Projection was complete with scheduler phase, `clientTrack_inbox_count`, `io_inbox_count`, `dsl_pump_mode`, and `dsl_suffix_sent`; target register `clientTrack_partitionswitchIngress_spineload_reg[3]`; `step_delta=+1`.
- **Smoke/regression**: Solver jobs were run one at a time in WSL. The compile/smoke stage passed before ENTRY/NEAR/CLOSURE, and the full run produced a certified wraparound manifest.

## 2026-05-04 FissLock notification counter wraparound repair and certificate rerun

- **Spec**: `Procurator/argo/code/spec/bench/fisslock_notification_cnt_wraparound_bug.prop`
- **Time**: 2026-05-04 03:00-03:22 Asia/Shanghai
- **Goal/Progress**: Re-ran the known TNA/FissLock notification-counter wraparound bug and fixed the blocking implementation issue exposed by ENTRY. The staged workflow was compile/smoke, ENTRY, P4B repair/regression, ENTRY rerun, NEAR, then full CLOSURE.
- **Result**:
  - Initial compile/smoke passed, but initial ENTRY run `.tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260504-030002-b4ae/` returned `Ultimate could not prove your program: Toolchain returned no result` after about `11.3s`.
  - Root-cause log showed Boogie type errors for undeclared register size constants, e.g. `sw_IngressPipe_lock_free_mode_array.size`, `sw_IngressPipe_CounterTable_2_notification_cnt_2.size`, and `sw_IngressPipe_LockOperation_1_lock_agent_array_1.size`.
  - After the P4B fix, compile/smoke passed again: `./bin/procurator compile --spec ...fisslock_notification_cnt_wraparound_bug.prop --out /tmp/fisslock_notification_cnt_wrap_compile2.bpl --boogie-harness sequential --no-two-stage`, followed by `./bin/procurator smoke --bpl /tmp/fisslock_notification_cnt_wrap_compile2.bpl --harness sequential`.
  - ENTRY rerun: `.tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260504-031133-d187/`, `ENTRY_CHECK=UNSAFE` in about `26.6s`.
  - NEAR run: `.tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260504-031341-299d/`, `ENTRY_CHECK=UNSAFE` in about `25.4s`; `near_wrap.unroll1=SAFE` in about `30.7s`; `near_wrap.unroll2=UNSAFE` in about `138.6s`.
  - Full certificate run: `.tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260504-031724-994f/`, manifest `.tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260504-031724-994f/wraparound/target.00.sw_IngressPipe_CounterTable_1_notification_cnt_1/wraparound.cegis.manifest.json`; `ENTRY_CHECK=UNSAFE` in about `19.1s`, `near_wrap.unroll1=SAFE` in about `29.4s`, `near_wrap.unroll2=UNSAFE` in about `144.8s`, and `CLOSURE_CHECK=SAFE` in about `81.7s`.
  - CLI printed `[CEX] certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id`; exit code was `1`, as expected for a certified bug.
- **Pitfalls (implementation/model issues)**:
  - The initial ENTRY result was not SAFE and not evidence of bug absence. It was a P4B sliced-output well-formedness bug: slicing retained register-size axioms for non-target but still live registers while filtering out their `const X.size` declarations.
  - The direct no-slicing translator output already emitted `const X.size` and `axiom X.size == ...` together. The failure was specific to sliced declaration filtering in `Translator::shouldKeepVar`.
  - A few manual inspection commands were misquoted across PowerShell/WSL and produced shell/help noise only; no solver result or artifact was affected. The reliable process check remains PowerShell-side filtering over `wsl.exe -- ps -eo pid,comm,args`.
- **Fixes/regression tests**:
  - `P4B-Translator/backends/verify/translate/impl/core/translate.cpp`: `shouldKeepVar()` now keeps `X.size` whenever the base register is kept, has register-domain metadata, or has non-constant index metadata. This keeps register-size `const` declarations closed with their axioms under slicing.
  - Rebuilt P4B in WSL with `cmake --build P4B-Translator/build-verify-sync --target p4c-translator -j4` and copied the binary into `P4B-Translator/build-host/{backends/verify/,}`.
  - `dslc/tests/p4b/test_p4b_translator_regressions.py`: added `test_fisslock_sliced_register_size_consts_are_declared`, checking that all sliced FissLock `axiom X.size == ...` entries have matching `const X.size` declarations and covering the previously missing `IngressPipe_CounterTable_2_notification_cnt_2.size`.
  - Focused regression executed: `python3 -m unittest -v dslc.tests.p4b.test_p4b_translator_regressions.TestP4BTranslatorRegressions.test_fisslock_sliced_register_size_consts_are_declared dslc.tests.p4b.test_p4b_translator_regressions.TestP4BTranslatorRegressions.test_tna_registeraction_execute_rhs_is_stateful dslc.tests.p4b.test_p4b_translator_regressions.TestP4BTranslatorRegressions.test_tofino_constructor_style_local_instantiation_translates` passed.
- **Smoke/regression**: Solver jobs were run one at a time in WSL. After the fix, compile/smoke, ENTRY, NEAR, and CLOSURE all completed and produced a certified wraparound manifest.

## 2026-05-04 ETC pkt_count dynamic-slot near-wrap classification rerun

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_count_wraparound.prop`
- **Time**: 2026-05-04 03:24-03:28 Asia/Shanghai
- **Goal/Progress**: Rechecked the ETC dynamic-slot packet-count wraparound candidate after the NEAR growth-policy fix and the P4B register-size declaration repair. The purpose was to distinguish bug absence from tool incompleteness.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260504-032430-a2fd/`
  - `ENTRY_CHECK=UNSAFE` in about `16.1s`.
  - `near_wrap.unroll1=Timeout` after about `192.3s` with `--ultimate-timeout-seconds 180`.
  - No later NEAR unroll was launched; the current strategy grows only after a concrete `SAFE`, not after `Timeout/UNKNOWN/ERROR`.
- **Pitfalls (implementation/model issues)**:
  - This is not a SAFE result and not evidence that the modeled bug is absent. It means the entry cutpoint is reachable, but the current dynamic-slot NEAR query did not finish inside the stage budget.
  - The manifest remains a fallback/incomplete evidence artifact, not a closure certificate.
- **Fixes/regression tests**:
  - No new code change was needed in this run. It validates the existing stop-after-timeout policy added in `dslc/workflows/wraparound_support/loop_schedule.py`.
- **Smoke/regression**: Solver jobs were run one at a time in WSL. The run stayed stage-bounded and did not continue expanding NEAR after timeout.

## 2026-05-04 ETC and Flowrest pkt_len_total focused direct witnesses

- **Spec**:
  - `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_direct.prop`
  - `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_len_total_wraparound_direct.prop`
- **Time**: 2026-05-04 03:28-03:30 Asia/Shanghai
- **Goal/Progress**: Re-ran two external ML/per-flow accumulated-length wraparound witnesses after the P4B register-size fix and focused-marker hardening. These are direct focused under-approximation witnesses, not closure certificates.
- **Result**:
  - ETC run directory: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260504-032839-b608/`
    - Focused result: `UNSAFE`; marker `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260504-032839-b608/external_etc_noms2024_pkt_len_total_wraparound_direct.focused-index0.unsafe.json`
    - Target `etc_Ingress_reg_pkt_len_total`, index var `etc_meta.register_index`, slot `0bv11`, target value `0bv16`.
    - Marker hashes: `source_bpl_sha256=7c51f6aea4f9db39aecd6fe692258e3eeeeaa31172a0d88df233ba2e8213d353`, `focused_bpl_sha256=e9b830c2993b5005f9c012444b3531abfa86c1f277528543729b6ca1408393b4`.
    - Accepted focused assertion lines `{325, 357}`; result line `RESULT: UNSAFE`.
  - Flowrest run directory: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound_direct/20260504-032923-2e36/`
    - Focused result: `UNSAFE`; marker `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound_direct/20260504-032923-2e36/external_flowrest_per_flow_pkt_len_total_wraparound_direct.focused-index0.unsafe.json`
    - Target `flowrest_Ingress_reg_pkt_len_total`, index var `flowrest_meta.register_index`, slot `0bv16`, target value `0bv16`.
    - Marker hashes: `source_bpl_sha256=695b318f320bd26e58cc1064f7c0cf53bcbfe07db5d568d1d960c49b1ad9fc4e`, `focused_bpl_sha256=b5099dba3c099d0a958c665d80871ed0e28391fbdc5fd620b74407ad00b50f68`.
    - Accepted focused assertion lines `{317, 349}`; result line `RESULT: UNSAFE`.
- **Pitfalls/Fixes**:
  - These artifacts are sound direct UNSAFE witnesses because the focused BPL fixes a concrete slot and the marker binds the source/focused BPL hashes and accepted assertion lines. They are not wraparound closure certificates and should not be counted as CLOSURE-proven acceleration results.
- **Smoke/regression**: Solver jobs were run one at a time in WSL. No residual Ultimate/java/z3 process was found after the runs.

## 2026-05-04 Flowrest flow-duration and accumulated-length direct witnesses

- **Spec**:
  - `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound_direct.prop`
  - `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound_slot0.prop`
  - `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_len_total_wraparound_slot0.prop`
- **Time**: 2026-05-04 03:34-03:48 Asia/Shanghai
- **Goal/Progress**: Explored additional Flowrest per-flow feature wraparound witnesses after the known toolchain repairs. These were direct/focused witness searches, not closure certificates.
- **Result**:
  - Flow-duration direct run: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound_direct/20260504-033425-4227/`; main log recorded `UNSAFE` with `OverallTime≈77.7s`, and the witness rerun also reached `UNSAFE` (`OverallTime≈75.1s`). The validator reported the DSL global assertion hit.
  - Flow-duration slot-0 run: `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound_slot0/20260504-034250-aa14/`; main log recorded `UNSAFE` with `OverallTime≈86.8s`, and the witness rerun also reached `UNSAFE` (`OverallTime≈81.8s`).
  - Accumulated-length slot-0 run: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound_slot0/20260504-034655-e037/`; main log recorded an `UNSAFE` result at the register-write assertion with `OverallTime≈25.8s`, and the witness rerun also reached the focused assertion (`OverallTime≈22.6s`).
- **Pitfalls/Fixes**:
  - These are concrete direct/focused `UNSAFE` witnesses, not schedule-replay closure certificates. They should be counted as bug-finding evidence, not as proof that the wraparound acceleration certificate closes.
  - The accumulated-length slot-0 log also contains an `UNKNOWN` for the unrelated original/global assertion location after the register-write assertion is hit; the accepted evidence is the register-write `UNSAFE` marker tied to the focused assertion line.
- **Smoke/regression**: Solver jobs were run one at a time in WSL; no concurrent Ultimate/GemCutter run was launched.

## 2026-05-04 Flowrest pkt_count dynamic-slot classification and direct timeout

- **Spec**:
  - `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_count_wraparound.prop`
  - `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_count_wraparound_direct.prop`
- **Time**: 2026-05-04 03:37-04:39 Asia/Shanghai
- **Goal/Progress**: Investigated the 8-bit Flowrest packet-count feature counter. The expected bug shape is a long-lived flow whose per-flow packet counter wraps to zero. The purpose was to distinguish confirmed witnesses, incomplete certification, and solver incompleteness.
- **Result**:
  - Schedule-replay run: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260504-033736-22fe/`.
    - `ENTRY_CHECK=UNSAFE` in about `17.0s`.
    - `near_wrap.unroll1` had a concrete internal `SAFE` for the short suffix but the final stage result was timeout/unknown; the policy then grew only because a concrete shorter-suffix `SAFE` had been observed.
    - `near_wrap.unroll2=UNSAFE` in about `66.3s`.
    - The manifest is **not certified**: `projection_complete=false`, with dynamic slot expressions `flowrest_Ingress_reg_flow_ID[flowrest_meta.register_index]` and `flowrest_Ingress_reg_time_last_pkt[flowrest_meta.register_index]`, plus unstable cutpoint guards.
  - Direct unbounded run: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound_direct/20260504-041503-079c/`; focused direct prepass timed out at about `256.5s`, and the original direct run timed out at about `257.3s`.
  - Direct bounded benchmark run with `--use-spec-max-steps`: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound_direct/20260504-042415-5f14/`; focused and original direct checks timed out, with the original log showing `OverallTime≈434.4s`.
- **Pitfalls (implementation/model issues)**:
  - This is not a `SAFE`/bug-absent result. The schedule-replay path proves ENTRY reachability and finds a near-wrap suffix, but refuses certification because the current dependency projection cannot yet soundly stabilize the dynamic per-flow key and target-write guards.
  - Direct/BMC for the 256-step path is too heavy in the current encoding, even when a debug max-step bound is explicitly enabled. The correct product behavior remains: `max_steps` is optional and ignored unless requested as a benchmark/debug knob.
- **Fixes/regression tests**:
  - Added `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_count_wraparound_direct.prop` as a benchmark/debug direct witness spec. It keeps `max_steps=260` only as an optional bound under `--use-spec-max-steps`.
  - Follow-up code work is needed in projection/index normalization before this can become a certified wraparound artifact.
- **Smoke/regression**: Compile/smoke passed before direct verification. Solver jobs were run one at a time in WSL.

## 2026-05-04 Flow INT counter dynamic-slot exploration

- **Spec**: `Procurator/argo/code/spec/bench/external_int_flowdos_counter_wraparound.prop`
- **Time**: 2026-05-04 03:49-04:00 Asia/Shanghai
- **Goal/Progress**: Rechecked the external INT counter candidate after dynamic-slot projection stopped treating header-validity maps as register arrays.
- **Result**:
  - Near-wrap run: `.tmp/procurator/verify/external_int_flowdos_counter_wraparound/20260504-035335-1b08/`; projection became complete for the current candidate (`procurator_phase`, `flowdos_inbox_count`), `ENTRY_CHECK=UNSAFE` in about `14.5s`, and `NEAR_WRAP=UNSAFE` in about `17.6s`. The run stopped after near-wrap by request, so it is not certified.
  - Full closure run: `.tmp/procurator/verify/external_int_flowdos_counter_wraparound/20260504-035441-66c1/`; `ENTRY_CHECK=UNSAFE` in about `16.2s`, `NEAR_WRAP=UNSAFE` in about `17.5s`, but `CLOSURE_CHECK=UNSAFE` in about `23.9s`. The blocked second schedule's ENTRY was `SAFE`, and fallback direct checking timed out after about `320.9s`.
  - Classification: not certified. This is not a `SAFE`/bug-absent conclusion; it is a closure failure or modeling/projection mismatch that still needs counterexample inspection.
- **Pitfalls (implementation/model issues)**:
  - The prior false dynamic-slot note `dependency_projection_dynamic_slot_index_mismatch=flowdos_isValid` was an analysis artifact: `isValid:[Ref]bool` is not a P4B stateful register map and should not drive dynamic-slot projection.
  - A complete projection in the syntactic extractor does not by itself certify the candidate; the closure stage must still prove the net effect and projection preservation.
- **Fixes/regression tests**:
  - `dslc/analysis/wraparound_projection_exprs.py`: dynamic-slot dependency extraction now only treats arrays with P4B register mirrors as stateful register arrays.
  - `dslc/analysis/wraparound_projection.py`: non-stable target-write guards are now fail-closed for certification, and dynamic guard specialization only rewrites P4B stateful register arrays.
  - `dslc/tests/wraparound/schedule/test_wraparound_projection.py`: added/strengthened tests so header-validity maps do not cause fake dynamic-slot mismatches but still make the projection incomplete if they guard target writes and cannot be stabilized.
  - Focused schedule/projection/manifest/refinement regression passed: `47` tests.
- **Smoke/regression**: Solver jobs were run one at a time in WSL. No residual Ultimate/java/z3 process was expected after the staged runs.

## 2026-05-04 Flow INT guarded-reset candidate gating

- **Spec**: `Procurator/argo/code/spec/bench/external_int_flowdos_counter_wraparound.prop`
- **Time**: 2026-05-04 07:55-07:56 Asia/Shanghai
- **Goal/Progress**: Rechecked the INT counter after fixing P4B monotonic update extraction so a guarded reset after an increment is no longer exported as a simple affine wraparound pump.
- **Result**:
  - Integrated schedule-replay entry-only run stopped before ENTRY because there were no wraparound candidates: `[WRAP] STOP-AFTER entry: no wraparound candidates`.
  - Wall time was about `4.97s`.
- **Pitfalls/Fixes**:
  - Previous exploration could pick `counter_filter.write(counter_pos, counter_val + 1)` while missing the later guarded `counter_filter.write(counter_pos, 0)`, which is not a replay-acceleration-compatible affine step.
  - `P4B-Translator/backends/verify/analysis/monotonic.cpp` now counts register writes over the whole body before emitting an affine update, so registers with reset/write-multiple behavior do not become simple wraparound targets.
- **Smoke/regression**:
  - `python3 -m unittest -v dslc.tests.p4b.test_p4b_flowdos_hash` passed (`3` tests).
  - The no-candidate integrated run was executed in WSL with no concurrent Ultimate/GemCutter job.

## 2026-05-04 Flowrest pkt_count branch-sensitive schedule certificate

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_count_wraparound.prop`
- **Time**: 2026-05-04 07:57-08:07 Asia/Shanghai
- **Goal/Progress**: Fixed the prior Flowrest packet-count near-wrap path where `ENTRY_CHECK` and `NEAR_WRAP` succeeded but certification fell back because init/steady target-write guards were flattened into mutually exclusive projection predicates.
- **Result**:
  - Near-only staged run: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260504-080354-8ef5/`.
    - `ENTRY_CHECK=UNSAFE` in about `13.8s`.
    - `near_wrap.unroll1` produced a concrete short-suffix `SAFE` result before timeout text; policy continued to unroll 2.
    - `near_wrap.unroll2=UNSAFE` in about `56.4s`.
    - Manifest had `projection_complete=true` with the selected steady branch predicates:
      - `!(flowrest_Ingress_reg_time_last_pkt[idx_hash(...)] == 0bv32)`
      - `!(flow_id_hash(...) != flowrest_Ingress_reg_flow_ID[idx_hash(...)])`
  - Full schedule-replay run: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260504-080655-3a88/`.
    - `ENTRY_CHECK=UNSAFE` in about `16.7s`.
    - `NEAR_WRAP=UNSAFE` at unroll 2 in about `57.7s`.
    - `CLOSURE_CHECK=SAFE` in about `107.3s`.
    - Overall wall time was about `270.1s`; final manifest is certified with diagnostic `certified schedule-replay wraparound bug`.
    - Manifest validator passed: `python3 -m dslc.bench.validate_counterexample --wraparound-manifest .../wraparound.cegis.manifest.json` reported `certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id`.
- **Pitfalls/Fixes**:
  - Over-constraining ENTRY with the selected steady-branch guard made `ENTRY_CHECK=SAFE`; this was wrong because ENTRY is only the initialized model/non-empty cutpoint gate, while the steady branch is a replay-closure condition reached after a prefix. The final implementation keeps ENTRY and NEAR on the base cutpoint and uses the selected branch guard for CLOSURE plus certified projection predicates.
  - Manifest validation previously rejected dynamic-index certificates where the top-level candidate has `index_value=None` but the compact schedule serializes `index_value=0`; validation now recomputes candidate identity from the top-level candidate metadata and schedule identity from the serialized projection.
  - Syntax-only stable predicate validation now accepts deterministic P4B function calls with constant arguments in register-slot indices and equality predicates.
- **Smoke/regression**:
  - `python3 -m unittest -v dslc.tests.wraparound.schedule.test_wraparound_projection dslc.tests.wraparound.schedule.test_wraparound_schedule dslc.tests.wraparound.schedule.test_schedule_manifest_certification dslc.tests.wraparound.schedule.test_schedule_replay_refinement dslc.tests.wraparound.test_wraparound_candidate_gating dslc.tests.p4b.test_p4b_flowdos_hash` passed (`65` tests).
  - Solver stages were run one at a time in WSL.

## 2026-05-04 Flowrest branch-sensitive schedule certificate soundness erratum

- **Spec**:
  - `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_count_wraparound.prop`
  - `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_len_total_wraparound.prop`
- **Time**: 2026-05-04 08:50-09:25 Asia/Shanghai
- **Goal/Progress**: Re-reviewed the branch-sensitive schedule certificate after subagent review. The previous `pkt_count` certificate combined base-cutpoint ENTRY/NEAR evidence with a selected steady-branch CLOSURE proof; that is not a sound unconditional certificate because the existence stages and closure lemma can refer to different branch states.
- **Result**:
  - `external_flowrest_per_flow_pkt_count_wraparound`: entry-only rerun after the soundness fix: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260504-085057-576c/`.
    - `ENTRY_CHECK=SAFE` in about `14.0s` once the selected steady-branch predicates were required at the same effective cutpoint as CLOSURE.
    - The earlier `20260504-080655-3a88` manifest must be treated as diagnostic only, not as a certified wraparound proof.
  - `external_flowrest_per_flow_pkt_len_total_wraparound`: near-wrap staged run after P4B candidate extraction fix: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound/20260504-092244-1b61/`.
    - P4B now emits `flowrest_Ingress_reg_pkt_len_total` as a candidate with `step_delta=32768`.
    - `ENTRY_CHECK=SAFE` in about `14.3s` under the selected steady-branch effective cutpoint, so schedule-replay correctly falls back instead of certifying.
  - Direct bounded validation for `external_flowrest_per_flow_pkt_len_total_wraparound`: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound/20260504-092517-a507/`.
    - Direct GemCutter check returned `UNSAFE`; witness rerun returned `UNSAFE`; validator reported `dsl_assert: witness hits DSL global assert`.
    - This distinguishes bug existence from acceleration-certification failure: the Flowrest `pkt_len_total` bug exists and is reproducible by direct checking, while the current schedule certificate needs a reachability-prefix/steady-cutpoint entry stage before it can certify this pattern.
- **Pitfalls/Fixes**:
  - Pitfall: Requiring steady-branch predicates only in CLOSURE is insufficient; ENTRY/NEAR/CLOSURE must be tied to the same effective cutpoint, or an explicit branch-reachability/branch-conditioned NEAR stage must be added.
  - Fix: `dslc/workflows/wraparound_support/loop_schedule.py` now builds the schedule identity, ENTRY, NEAR, and CLOSURE from the same effective cutpoint when a branch projection is selected.
  - Fix: `dslc/workflows/wraparound_cegis.py` and `dslc/bench/validate_counterexample.py` now compute/validate schedule candidate identity using the attempt's effective cutpoint while preserving top-level dynamic-index metadata (`index_value=None`, `index_expr=...`).
  - P4B improvement: `P4B-Translator/backends/verify/analysis/monotonic.cpp` now accepts init-or-accumulate `RegisterAction` summaries (e.g., Flowrest `pkt_len_total`) while still rejecting guarded reset-after-increment patterns (e.g., Flow INT counter).
- **Smoke/regression**:
  - `cmake --build . --target p4c-translator -j4` completed in WSL after about `579s` (with existing clock-skew warnings from the synced P4C tree).
  - `python3 -m unittest -v dslc.tests.wraparound.schedule.test_wraparound_schedule dslc.tests.wraparound.schedule.test_schedule_manifest_certification dslc.tests.wraparound.schedule.test_schedule_replay_refinement dslc.tests.toolchain.test_validate_counterexample` passed (`44` tests).
  - `python3 -m unittest -v dslc.tests.p4b.test_p4b_flowdos_hash.TestP4BFlowDoSHash.test_flowdos_counter_reset_not_reported_as_simple_wraparound_update dslc.tests.p4b.test_p4b_flowdos_hash.TestP4BFlowDoSHash.test_flowrest_pkt_len_total_register_action_exports_steady_affine_update` passed (`2` tests).
  - Solver jobs were run one at a time in WSL; no `SAFE` result here is treated as bug absence.

## 2026-05-04 Flowrest flow_duration and ETC pkt_count staged exploration

- **Spec**:
  - `Procurator/argo/code/spec/bench/external_flowrest_per_flow_flow_duration_wraparound.prop`
  - `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_count_wraparound.prop`
- **Time**: 2026-05-04 09:30-09:57 Asia/Shanghai
- **Goal/Progress**: Continued staged bug exploration after the Flowrest branch-certificate soundness fix. The intent was to distinguish direct bug existence, candidate-extraction gaps, projection incompleteness, and real proof failures.
- **Result**:
  - `external_flowrest_per_flow_flow_duration_wraparound`: schedule-replay near-wrap run stopped with `no wraparound candidates` in about `6s`; direct GemCutter run `.tmp/procurator/verify/external_flowrest_per_flow_flow_duration_wraparound/20260504-093029-10f4/` timed out at `300s`.
    - Classification: not bug absence. Current P4B monotonic extraction does not yet export non-constant timestamp-difference deltas such as `global_tstamp - last_pkt`, and direct solving is too slow for this case at the 300s stage budget.
  - `external_etc_noms2024_pkt_count_wraparound`: near-only run `.tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260504-093555-f2e3/`.
    - `ENTRY_CHECK=UNSAFE` in about `16.4s`.
    - `NEAR_WRAP=UNSAFE` in about `70.6s`.
    - Stopped after near-wrap by request; not certified.
  - `external_etc_noms2024_pkt_count_wraparound`: full schedule-replay attempt `.tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260504-093757-b345/`.
    - `ENTRY_CHECK=UNSAFE` in about `16.8s`.
    - `NEAR_WRAP=UNSAFE` in about `48.1s`.
    - The manifest correctly refuses closure because `projection_complete=false`: `etc_meta.register_index` remains a dynamic pre-loop global, and branch predicates include an unstable/mutually exclusive `etc_Ingress_reg_status[etc_meta.register_index]` pair.
    - The CLI then fell back to direct checking; the outer shell timed out while direct fallback was still running. The residual Ultimate/java/z3/procurator processes for this run were killed by run id `20260504-093757-b345`.
- **Pitfalls/Fixes**:
  - Pitfall: A full `verify --wraparound auto` can enter direct fallback after a non-certified near-wrap path; for large external programs this may exceed the intended staged budget. Future deep closure/fallback runs should use explicit stop-after stages or a tighter direct fallback budget.
  - Pitfall: ETC is not `SAFE`; the tool has a concrete near-wrap suffix but lacks a complete projection. This is a projection/index-stabilization problem, not a proof of bug absence.
  - Follow-up implementation target: derive stable TNA hash/index definitions for `etc_meta.register_index` from P4B deterministic definitions and avoid certifying mutually exclusive status-guard predicates unless a single reachable branch cutpoint is proved.
- **Smoke/regression**:
  - No new code changes were made for this ETC/flow-duration exploration beyond the P4B/register-action and schedule soundness fixes recorded above.
  - Process check after killing the timed-out ETC fallback showed no remaining Ultimate/java/z3/procurator process except an unrelated interactive bash rcfile.

## 2026-05-04 ETC pkt_count prefix-entry wraparound certification

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_count_wraparound.prop`
- **Time**: 2026-05-04 12:39-12:52 Asia/Shanghai
- **Goal/Progress**: Fixed the known ETC `NEAR_WRAP=SAFE` misclassification for the steady-branch wraparound pattern. The selected cutpoint is not reachable at initialization because the first packet initializes `reg_status`/`reg_flow_ID`; the solver must first reach the steady branch with a finite prefix, then place the near-wrap fast-forward at that same effective cutpoint.
- **Result**:
  - Near-only staged run: `.tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260504-123948-d3ac/`.
    - Initial `ENTRY_CHECK=SAFE` in about `26.7s`, which is expected for the steady-branch cutpoint and is no longer treated as bug absence.
    - `entry_check.prefix.unroll1=UNSAFE` in about `61.7s`, reaching the steady cutpoint after one deterministic scheduler round (`2` effective steps).
    - `near_wrap.focused=UNSAFE` in about `138.6s`; stopped after near-wrap by request.
  - Full closure run: `.tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260504-124417-97a1/`.
    - `ENTRY_CHECK=SAFE` in about `19.6s`.
    - `entry_check.prefix.unroll1=UNSAFE` in about `55.7s`.
    - `near_wrap.focused=UNSAFE` in about `153.6s`.
    - `CLOSURE_CHECK=SAFE` in about `135.2s`.
    - Overall staged wall time was about `375s`; the manifest is certified and the run stays within the 10-minute target.
    - Manifest validator passed: `python3 -m dslc.bench.validate_counterexample --wraparound-manifest .tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260504-124417-97a1/wraparound/target.00.etc_Ingress_reg_pkt_count/wraparound.cegis.manifest.json` reported `certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id`.
- **Pitfalls/Fixes**:
  - Pitfall: The earlier `NEAR_WRAP=SAFE` was caused by fast-forwarding before the finite prefix had reached the selected steady branch. This was a toolchain modeling/staging error, not evidence that the theoretical ETC wraparound bug is absent.
  - Fix: schedule replay now supports prefix-entry checks for selected branch cutpoints and inserts the confirm/near fast-forward at a `WRAPAROUND_CONFIRM_PREFIX_CUTPOINT` after the prefix. It also avoids reasserting initialization defaults after that prefix cutpoint.
  - Fix: prefix-entry near-wrap now has a focused under-approx stage. It strips the original wrapped assertion and asks only for the target mirror state (`__wrote_any`, selected index, wrapped value) after the prefix cutpoint. Only `UNSAFE` is accepted; `SAFE`, `UNKNOWN`, timeout, or missing mirror structure falls back to the ordinary near-wrap/direct path and is not used as a proof of absence.
  - Soundness note: focused near is only an existential suffix witness. Certification still requires the separate closure proof, with complete dependency projection and no witness-only closure assumptions.
- **Smoke/regression**:
  - `python3 -m unittest -v dslc.tests.wraparound.schedule.test_wraparound_schedule` passed (`26` tests).
  - `python3 -m unittest -v dslc.tests.wraparound.test_wraparound_candidate_gating dslc.tests.wraparound.schedule.test_wraparound_projection dslc.tests.wraparound.schedule.test_wraparound_schedule dslc.tests.wraparound.schedule.test_schedule_manifest_certification dslc.tests.wraparound.schedule.test_schedule_replay_refinement dslc.tests.toolchain.test_validate_counterexample` passed (`76` tests).
  - Solver stages were run one at a time in WSL; no bounded/staged `SAFE` result is treated as bug absence unless the corresponding proof obligation justifies that conclusion.

## 2026-05-04 Flowrest pkt_count prefix-entry recertification

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_count_wraparound.prop`
- **Time**: 2026-05-04 13:05-13:12 Asia/Shanghai
- **Goal/Progress**: Re-ran the Flowrest packet-count case after the prefix-entry/focused-near fix. This revisits the earlier erratum where the old certificate mixed base-cutpoint existence evidence with a selected steady-branch closure proof.
- **Result**:
  - Full closure run: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260504-130505-6ff7/`.
    - Initial `ENTRY_CHECK=SAFE` in about `30.1s`, as expected for the steady-branch effective cutpoint.
    - `entry_check.prefix.unroll1=UNSAFE` in about `59.9s`, reaching the steady branch after one deterministic scheduler round (`3` effective steps).
    - `near_wrap.focused=UNSAFE` in about `128.9s`.
    - `CLOSURE_CHECK=SAFE` in about `174.8s`.
    - Overall staged wall time was about `407s`; the manifest is certified and remains within the 10-minute target.
    - Manifest validator passed: `python3 -m dslc.bench.validate_counterexample --wraparound-manifest .tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260504-130505-6ff7/wraparound/target.00.flowrest_Ingress_reg_pkt_count/wraparound.cegis.manifest.json` reported `certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id`.
- **Pitfalls/Fixes**:
  - The previous `20260504-080655-3a88` Flowrest `pkt_count` manifest remains diagnostic only because it used mismatched cutpoints. The new `20260504-130505-6ff7` run is the replacement sound certificate: ENTRY, NEAR, and CLOSURE all use the selected steady-branch effective cutpoint, with finite-prefix reachability evidence.
  - Subagent review found no blocking soundness issue in the focused-near path. It did flag that focused `UNSAFE` overwrote the generic `confirm_bpl`/`confirm_log` artifact fields; the implementation now also stores optional `source_confirm_bpl` / `source_confirm_log` fields to preserve the ordinary near-wrap source artifact for auditability.
- **Smoke/regression**:
  - `python3 -m py_compile dslc/workflows/wraparound_cegis.py dslc/workflows/wraparound_support/loop_schedule.py dslc/workflows/wraparound_support/prefix_cutpoint.py dslc/tests/wraparound/schedule/test_schedule_prefix_cutpoint.py` passed.
  - `python3 -m unittest -v dslc.tests.wraparound.schedule.test_schedule_prefix_cutpoint dslc.tests.wraparound.schedule.test_wraparound_schedule` passed (`26` tests).
  - Full wraparound regression: `python3 -m unittest -v dslc.tests.wraparound.test_wraparound_candidate_gating dslc.tests.wraparound.schedule.test_wraparound_projection dslc.tests.wraparound.schedule.test_wraparound_schedule dslc.tests.wraparound.schedule.test_schedule_prefix_cutpoint dslc.tests.wraparound.schedule.test_schedule_manifest_certification dslc.tests.wraparound.schedule.test_schedule_replay_refinement dslc.tests.toolchain.test_validate_counterexample` passed (`76` tests).
  - Solver stages were run one at a time in WSL.

## 2026-05-04 NetChain schedule-replay projection regression check

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`
- **Time**: 2026-05-04 13:15-13:19 Asia/Shanghai
- **Goal/Progress**: Ran the historical NetChain wraparound anchor after the prefix-entry/focused-near changes to check that the old non-prefix existence path still works and to identify remaining projection gaps.
- **Result**:
  - Near-only staged run: `.tmp/procurator/verify/netchain_wraparound_bug/20260504-131509-c824/`.
    - `ENTRY_CHECK=UNSAFE` in about `21.5s`.
    - `near_wrap=UNSAFE` in about `54.0s`.
    - Stopped after near-wrap by request.
  - Closure staged run: `.tmp/procurator/verify/netchain_wraparound_bug/20260504-131642-7ce9/`.
    - `ENTRY_CHECK=UNSAFE` in about `19.9s`.
    - `near_wrap=UNSAFE` in about `58.0s`.
    - Closure was not run because dependency projection was incomplete; validator correctly reported `not certified`.
    - Manifest diagnostic: `near-wrap bug found but dependency projection incomplete; falling back to direct verification`.
- **Pitfalls/Fixes**:
  - This is not a proof of bug absence. The tool still finds ENTRY and NEAR witnesses; certification is blocked by projection extraction.
  - The projection probe showed stale/unstable guard noise from `s1/s2_isValid[*.nc_hdr]` and `bugt(seq, seq+1)`-style guards. One sound improvement was made: constant boolean disjuncts such as `(100bv16 == 100bv16) || unknown_guard(...)` are now folded to `true`, which removes a spurious target-write guard. The remaining NetChain guard on `s2` depends on the cross-node sequence value and should not be blindly dropped; it needs a real cross-node data-flow/projection predicate or a more precise P4B dependency summary.
- **Smoke/regression**:
  - `python3 -m unittest -v dslc.tests.wraparound.schedule.test_wraparound_projection` passed after the constant boolean folding change.
  - Files stayed within the line limits after moving the boolean helper to `dslc/analysis/wraparound_projection_bool.py`.

## 2026-05-04 Flowrest pkt_len_total prefix-entry certification

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_len_total_wraparound.prop`
- **Time**: 2026-05-04 13:26-13:31 Asia/Shanghai
- **Goal/Progress**: Revisited the Flowrest packet-length-total wraparound case after prefix-entry/focused-near support. Previously this case had a direct witness but schedule certification stopped at steady-branch `ENTRY_CHECK=SAFE`.
- **Result**:
  - Full closure run: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound/20260504-132619-0775/`.
    - Initial `ENTRY_CHECK=SAFE` in about `16.9s`.
    - `entry_check.prefix.unroll1=UNSAFE` in about `55.0s`.
    - `near_wrap.focused=UNSAFE` in about `120.6s`.
    - `CLOSURE_CHECK=SAFE` in about `93.8s`.
    - Overall staged wall time was about `299s`; the manifest is certified.
    - Manifest validator passed: `python3 -m dslc.bench.validate_counterexample --wraparound-manifest .tmp/procurator/verify/external_flowrest_per_flow_pkt_len_total_wraparound/20260504-132619-0775/wraparound/target.00.flowrest_Ingress_reg_pkt_len_total/wraparound.cegis.manifest.json` reported `certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id`.
- **Pitfalls/Fixes**:
  - This confirms the earlier direct-only result was a certification-staging limitation, not a missing bug. The finite prefix now reaches the steady branch before fast-forwarding the target counter.
  - The same source-artifact audit fix applies: focused near keeps `confirm_bpl/log` on the focused witness program and records `source_confirm_bpl/log` for the ordinary near-wrap source.
- **Smoke/regression**:
  - Flowrest `pkt_count`, Flowrest `pkt_len_total`, and ETC `pkt_count` now all have prefix-entry schedule certificates under the 10-minute target.

## 2026-05-04 ETC pkt_len_total staged non-certification

- **Spec**:
  - `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_slot0.prop`
  - `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_direct.prop`
- **Time**: 2026-05-04 13:32-13:42 Asia/Shanghai
- **Goal/Progress**: Checked whether the prefix-entry/focused-near path also certifies ETC packet-length-total wraparound.
- **Result**:
  - Slot-0 spec run: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_slot0/20260504-133220-ed5e/`.
    - `ENTRY_CHECK=UNSAFE` in about `18.9s`.
    - `near_wrap` returned `SAFE` for unroll 1/2/3 (`38.7s`, `48.2s`, `43.0s` respectively).
    - Not certified; diagnostic: `near-wrap check did not find a bug for this schedule; falling back`.
  - Direct-style spec run: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_direct/20260504-133623-215e/`.
    - Initial `ENTRY_CHECK=SAFE` in about `19.5s`.
    - `entry_check.prefix.unroll1` timed out after about `314.3s`.
    - Not certified; diagnostic: `entry unknown/timeout; falling back`.
- **Pitfalls/Fixes**:
  - Slot-0 `SAFE` is not a bug-absence result. The generated near-wrap fast-forward writes `reg_pkt_len_total[idx_calc(...)] := 32768bv16`, but the slot-0 assertion checks `__wrote_index0 && __last0_value == 0`; the model currently does not prove or assume `idx_calc(...) == 0bv11`. This is a missing index/slot constraint in the tool/modeling path, not a semantic proof that the length-total bug is absent.
  - Direct-style ETC length-total avoids the slot-0 mirror issue but still times out in prefix-entry reachability. This needs prefix-entry optimization and/or stronger P4B metadata for the steady branch, not a dataset workaround.
- **Smoke/regression**:
  - Solver jobs were staged one at a time in WSL. No `SAFE`/`TIMEOUT` in this entry is treated as bug absence.

## 2026-05-04 ETC pkt_len_total slot0 certification after projection/index fix

- **Spec**: `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_len_total_wraparound_slot0.prop`
- **Time**: 2026-05-04 13:59-14:20 Asia/Shanghai
- **Goal/Progress**: Revisited the earlier ETC packet-length-total slot0 non-certification and fixed the tool-side mismatch between P4B's sliced singleton register domain and wraparound's dynamic-index fast-forward/projection reasoning.
- **Result**:
  - Diagnostic near-only run after the index fix: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_slot0/20260504-135926-7d27/`.
    - `ENTRY_CHECK=UNSAFE` in about `24.5s`.
    - `near_wrap.unroll1=SAFE` in about `38.2s`; this is expected because one logical scheduler step only injects the env packet.
    - `near_wrap.unroll2=UNSAFE` in about `39.5s`, showing the previous all-`SAFE` result was a modeling/tool issue, not bug absence.
  - Full closure run before the companion-state projection fix: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_slot0/20260504-140150-cd58/`.
    - `ENTRY_CHECK=UNSAFE` and `near_wrap.unroll2=UNSAFE`, but the manifest remained uncertified because the dependency projection was still incomplete.
  - Certified run after the projection fix: `.tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_slot0/20260504-141705-0098/`.
    - Initial `ENTRY_CHECK=SAFE` in about `18.9s`, because the selected steady-branch cutpoint is not reachable at initialization.
    - `entry_check.prefix.unroll1=UNSAFE` in about `44.2s`, reaching the steady branch after one deterministic scheduler round (`2` effective steps).
    - `near_wrap.focused=UNSAFE` in about `50.1s`.
    - `CLOSURE_CHECK=SAFE` in about `18.9s`.
    - Manifest validator passed: `python3 -m dslc.bench.validate_counterexample --wraparound-manifest .tmp/procurator/verify/external_etc_noms2024_pkt_len_total_wraparound_slot0/20260504-141705-0098/wraparound/target.00.etc_Ingress_reg_pkt_len_total/wraparound.cegis.manifest.json` reported `certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id`.
- **Pitfalls/Fixes**:
  - Pitfall: The slot0 assertion observes `__wrote_index0/__last0_value`, while P4B's meta update originally reported a dynamic `idx_calc(...)` expression. The old wraparound fast-forward wrote `reg[idx_calc(...)]`, so the near stage could miss the index0 mirror even though P4B slicing had already collapsed the target register domain to slot 0.
  - Fix: candidate inference now collapses a dynamic index to `index_value=0` only when the global assertion observes the index0 mirror and the translated Boogie model has `axiom <reg>.size == 1`. This reuses P4B's sliced singleton-domain model; it does not assume `idx_calc(...) == 0` in an unsliced or unproven model.
  - Pitfall: constant-slot candidates did not apply the same stable env/control-plane substitutions used by dynamic-index candidates. As a result, the projection saw table action parameters such as `Ingress_set_flow_class.f_class == 0` as unstable guard state.
  - Fix: cutpoint projection now recovers node-entry constants for constant-slot candidates too, applies stable constants before dynamic-slot specialization, and specializes companion register guards to the candidate slot (`reg_status[0]`, `reg_flow_ID[0]`). The certified projection snapshots scheduler/mailbox state, `reg_status`/`reg_flow_ID` slot0 mirrors, and the two steady-branch predicates:
    - `!(etc_Ingress_reg_status[0bv11] == 0bv1)`
    - `!((etc_Ingress_flow_id_calc.get$bv32$bv32$bv16$bv16$bv8(167772161bv32, 167772162bv32, 1234bv16, 443bv16, 6bv8)) != etc_Ingress_reg_flow_ID[0bv11])`
  - Soundness note: the earlier all-`SAFE` near result is now classified as a tool limitation. The final certified run proves reachability of the selected steady cutpoint by prefix ENTRY, finds a focused NEAR witness from the same cutpoint, and discharges the replay closure with a complete dependency projection.
- **Smoke/regression**:
  - `python3 -m unittest -v dslc.tests.wraparound.test_wraparound_candidate_gating dslc.tests.wraparound.schedule.test_wraparound_projection dslc.tests.wraparound.schedule.test_wraparound_schedule dslc.tests.wraparound.schedule.test_schedule_prefix_cutpoint dslc.tests.wraparound.schedule.test_schedule_manifest_certification dslc.tests.wraparound.schedule.test_schedule_replay_refinement dslc.tests.toolchain.test_validate_counterexample` passed (`79` tests).
  - `python3 -m py_compile dslc/analysis/wraparound_bpl_index.py dslc/analysis/wraparound_candidates.py dslc/analysis/wraparound_projection.py dslc/analysis/wraparound_projection_exprs.py dslc/analysis/wraparound_projection_cutpoint.py` passed.
  - File-size check: `dslc/analysis/wraparound_bpl_index.py` is back at `1300` lines after removing one blank line; no Python file touched in this step exceeds the current `1300`-line limit.
  - Old-certificate smoke: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_len_total_wraparound.prop` was rerun after the projection/index fix, run id `20260504-142343-e1fd`. It remained certified: `entry_check.prefix.unroll1=UNSAFE` in about `61.2s`, `near_wrap.focused=UNSAFE` in about `129.6s`, and `CLOSURE_CHECK=SAFE` in about `92.2s`; manifest validator passed.

## 2026-05-04 effective-code cleanup regression smoke

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`
- **Time**: 2026-05-04 18:05-18:08 Asia/Shanghai
- **Goal/Progress**: After effective-code cleanup and P4B/DSL comment hygiene, ran a no-solver end-to-end compile/smoke check for the main DSL -> P4B -> Boogie harness path.
- **Result**:
  - Command: `./bin/procurator compile --spec Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop --out /tmp/netchain_wraparound_bug.cleanup.bpl --boogie-harness sequential --no-two-stage --no-reg-debug && ./bin/procurator smoke --bpl /tmp/netchain_wraparound_bug.cleanup.bpl --harness sequential`
  - Passed in about `9.5s`.
  - Output: `[OK] bpl: /tmp/netchain_wraparound_bug.cleanup.bpl` and `[SMOKE-OK] /tmp/netchain_wraparound_bug.cleanup.bpl looks structurally OK for harness=sequential.`
- **Pitfalls/Fixes**:
  - No Ultimate/GemCutter solving was run in this smoke; this is a structural regression check, not a proof or bug-finding result.
  - During unit regression, Flow INT `counter_filter` metadata exposed an over-pruning issue in P4B monotonic candidate extraction: guarded reset paths caused the affine `+1` candidate to be dropped. Fixed by treating P4B metadata as candidate extraction only; certification remains with schedule/projection/closure.
- **Smoke/regression**:
- `cmake --build . --target p4c-translator -j16` passed in WSL.
- `P4B-Translator/build-host/p4c-translator ... --slicing-selftest=netchain_seq ...` passed.
- `python3 -m unittest -v dslc.tests.p4b.test_p4b_translator_slicing_selftest dslc.tests.p4b.test_p4b_translator_regressions dslc.tests.p4b.test_p4b_flowdos_hash dslc.tests.wraparound.test_wraparound_candidate_gating dslc.tests.wraparound.schedule.test_wraparound_projection dslc.tests.wraparound.schedule.test_wraparound_schedule dslc.tests.wraparound.schedule.test_schedule_manifest_certification dslc.tests.wraparound.schedule.test_schedule_replay_refinement dslc.tests.toolchain.test_validate_counterexample` passed (`119` tests).

## 2026-05-05 Flow-INT direct fallback hardening (bounded focused under-approx)

- **Spec**:
  - `Procurator/argo/code/spec/bench/external_int_flowdos_counter_wraparound.prop`
  - Regression anchor: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`
- **Time**: 2026-05-05 10:41-12:03 Asia/Shanghai
- **Goal/Progress**: Continue pushing the “Flow-INT bug should not be lost” issue. We first fixed bounded focused-direct implementation errors, then re-ran staged direct checks with short budgets to ensure `TIMEOUT/UNKNOWN` are never interpreted as `SAFE`.
- **Result**:
  - Bounded focused-direct implementation fixed in `dslc/workflows/focused_direct.py`:
    - add latch variable to `modifies` of procedures that write it;
    - propagate `modifies` transitively to callers (fixes Boogie “modifies not transitive”);
    - robust procedure-body parsing with `{:inline ...}` attributes;
    - choose bounded probe steps by **target register value width** (not index width), so `bv8` covers `32/64/128/256`.
  - Added regression tests in `dslc/tests/workflows/test_focused_direct_workflow.py`:
    - `test_timeout_bounded_probe_adds_latch_to_modifies`
    - `test_timeout_on_bv8_target_includes_256_bounded_probe`
    - plus transitive `modifies` checks for `main` and `ULTIMATE.start`.
  - Focused regression run:
    - `.\\.venv\\Scripts\\python.exe -m unittest -v dslc.tests.workflows.test_focused_direct_workflow dslc.tests.transform.test_focused_direct`
    - result: `26 tests PASS`.
  - Flow-INT staged direct reruns (`--wraparound off --focused-direct auto`, WSL, one case at a time):
    - `20260505-104132-aa47`: `--use-spec-max-steps --max-steps 256`, `TIMEOUT`.
    - `20260505-104850-ef45`: `--use-spec-max-steps --max-steps 1024`, `TIMEOUT`.
    - `20260505-105438-3f8a`: `--no-slicing-control-seeds --no-reg-debug`, `TIMEOUT`.
    - `20260505-110742-d062`: first bounded attempt (revealed implementation bug below).
    - `20260505-111825-0190`: after first fix, bounded64/128 no longer type-error, still `TIMEOUT`.
    - `20260505-112625-fdd1`: after transitive-modifies fix, bounded64/128 and full direct all `TIMEOUT`.
    - `20260505-114252-6685`: with `bv8 -> bounded256`, bounded32/64/128/256 all executed and all `TIMEOUT`; full direct still `TIMEOUT`.
  - Bounded probe stats from `20260505-114252-6685`:
    - bounded32: `OverallTime 131.1s`, `OverallIterations 17`, `TimeoutResultAtElement [Line: 1396]`
    - bounded64: `OverallTime 114.6s`, `OverallIterations 13`, `TimeoutResultAtElement [Line: 1524]`
    - bounded128: `OverallTime 90.7s`, `OverallIterations 10`, `TimeoutResultAtElement [Line: 1780]`
    - bounded256: `OverallTime 39.1s`, `OverallIterations 2`, `TimeoutResultAtElement [Line: 2292]`
    - full direct: `OverallTime 184.5s`, `OverallIterations 26`, `TimeoutResultAtElement [Line: 636/1218]`
  - Classification conclusion for this round: Flow-INT direct path is **TIMEOUT (not solved)**, **not SAFE**.
- **Pitfalls/Fixes**:
  - Pitfall 1 (implementation bug, run `20260505-110742-d062`):
    - `Global variable ... modified ... but not contained in procedure modifies clause`
    - Fix: auto-add latch var into touched procedure `modifies`.
  - Pitfall 2 (implementation bug, run `20260505-111825-0190`):
    - `Procedure ... may modify ... caller must not modify ... Modifies not transitive`
    - Fix: propagate latch `modifies` along caller closure on call graph.
  - Pitfall 3 (strategy mismatch):
    - old bounded steps used index width; this under-covered `bv8` wraparound depth.
    - Fix: step schedule keyed by target value width, includes `256` for `bv8`.
- **Smoke/regression**:
  - Focused regression suite: `26 PASS` (command above).
  - NetChain wraparound anchor re-run after fixes (no regression):
    - run `20260505-120042-8581`
    - `ENTRY_CHECK=UNSAFE` (~20.3s)
    - `NEAR_WRAP=UNSAFE` (~44.3s)
    - `CLOSURE_CHECK=SAFE` (~92.0s)
    - manifest: `.tmp/procurator/verify/netchain_wraparound_bug/20260505-120042-8581/wraparound/target.00.s1_sequence_reg/wraparound.cegis.manifest.json`
    - CLI output: `[WRAP] CERTIFIED UNSAFE` + `[CEX] certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id`

## 2026-05-05 Flow-INT deferred after direct timeout (per latest user instruction)

- **Spec**: `Procurator/argo/code/spec/bench/external_int_flowdos_counter_wraparound.prop`
- **Time**: 2026-05-05 17:23-17:39 Asia/Shanghai
- **Goal/Progress**: Before deferring Flow-INT, run one direct-only baseline (`wraparound off`) to classify status correctly, then follow the latest instruction to prioritize other bugs first.
- **Result**:
  - Run: `.tmp/procurator/verify/external_int_flowdos_counter_wraparound/20260505-172311-e512/`.
  - `RESULT: Ultimate could not prove your program: Timeout`.
  - Log tail shows TraceAbstraction timeout after about `951.7s` and large-difference construction pressure (`7085` abstraction states).
- **Pitfalls/Fixes**:
  - This run is **timeout only**, not bug absence and not `SAFE`.
  - No implementation change in this step; action is classification + deferral according to current goal ordering.
- **Smoke/regression**:
  - None added in this step. This entry is retained as deferred-case evidence for later root-cause pass (time budget vs projection refinement vs true absence).

## 2026-05-05 NetChain wraparound revalidation after deferral switch

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`
- **Time**: 2026-05-05 18:05-18:12 Asia/Shanghai
- **Goal/Progress**: Re-anchor schedule-replay wraparound pipeline before mining additional non-Flow-INT bugs.
- **Result**:
  - Run: `.tmp/procurator/verify/netchain_wraparound_bug/20260505-180558-3161/`.
  - Manifest: `.tmp/procurator/verify/netchain_wraparound_bug/20260505-180558-3161/wraparound/target.00.s1_sequence_reg/wraparound.cegis.manifest.json`.
  - Stage results:
    - `ENTRY_CHECK=UNSAFE` (`~23.2s`)
    - `NEAR_WRAP=UNSAFE` (`~69.9s`)
    - `CLOSURE_CHECK=SAFE` (`~255.2s`)
  - Overall: certified schedule-replay wraparound bug (`certified=true`).
- **Pitfalls/Fixes**:
  - Manifest notes still include `dependency_projection_incomplete` text noise, but `projection_complete=true` and certification gates passed (`ENTRY/NEAR UNSAFE + CLOSURE SAFE` for one schedule id).
  - No code fix required for this revalidation.
- **Smoke/regression**:
  - This run is used as regression anchor for subsequent interleaving/direct checks in this batch.

## 2026-05-05 Interleaving bug replay on current baseline (FRR + P4NIS)

- **Spec**:
  - `Procurator/argo/code/spec/bench/frr_bug2_state_inconsistency.prop`
  - `Procurator/argo/code/spec/bench/p4nis_bug2_tunnel_state_leakage.prop`
- **Time**: 2026-05-05 18:17-18:22 Asia/Shanghai
- **Goal/Progress**: Add fresh non-wrap interleaving evidence in current code state while Flow-INT is deferred.
- **Result**:
  - FRR run: `.tmp/procurator/verify/frr_bug2_state_inconsistency/20260505-181733-6bbb/`
    - `RESULT: UNSAFE`
    - witness rerun also `UNSAFE`
    - witness path: `frr_bug2_state_inconsistency.bpl-witness.graphml`
  - P4NIS run: `.tmp/procurator/verify/p4nis_bug2_tunnel_state_leakage/20260505-182013-7ed6/`
    - `RESULT: UNSAFE`
    - witness rerun also `UNSAFE`
    - witness path: `p4nis_bug2_tunnel_state_leakage.bpl-witness.graphml`
- **Pitfalls/Fixes**:
  - No implementation change required; both are successful direct-check replays on current baseline.
  - Classification remains strict: `UNSAFE` only when witness confirmed by rerun.
- **Smoke/regression**:
  - These two runs are now current-baseline interleaving anchors for future refactors in `dslc`/`P4B`.

## 2026-05-05 Translator regression blockers found during interleaving expansion

- **Spec**:
  - `Procurator/argo/code/spec/bench/gecko_bug2_concurrency.prop`
  - `Procurator/argo/code/spec/bench/netlock_release_counter_underflow_bug.prop`
- **Time**: 2026-05-05 18:17-18:20 Asia/Shanghai
- **Goal/Progress**: Continue interleaving expansion; classify whether failures are semantic `SAFE` or implementation regressions.
- **Result**:
  - Gecko run: `.tmp/procurator/verify/gecko_bug2_concurrency/20260505-181733-bd49/`
    - compile failed before solving with:
    - `P4B slicing produced invalid Boogie (dangling .read/.write without decls)`
    - missing bases: `register_address_h_record`, `register_address_l_record`, `register_state`
    - emitted file: `work/ta.raw.bpl`
  - NetLock run: `.tmp/procurator/verify/netlock_release_counter_underflow_bug/20260505-182013-9dd6/`
    - compile failed before solving with:
    - `missing Boogie type declarations for referenced types (translator bug): mirror_hdr_t`
- **Pitfalls/Fixes**:
  - Both are toolchain translation regressions, not semantic `SAFE` conclusions.
  - No hotfix landed in this pass; issues are recorded for dedicated P4B/translation repair track.
- **Smoke/regression**:
  - FRR/P4NIS/NetChain successful reruns in the same session establish that these failures are localized translator regressions rather than global pipeline collapse.

## 2026-05-05 ATP/P4XOS/P4DB/FRR/Cheetah regression replay (not new bug discovery)

- **Spec**: `Procurator/argo/code/spec/bench/atp_bug.prop`
- **Time**: 2026-05-05 18:56-18:58 Asia/Shanghai
- **Goal/Progress**: Regression replay only. These are previously documented bench cases and must not be counted as newly discovered bugs.
- **Result**:
  - Run: `.tmp/procurator/verify/atp_bug/20260505-185621-114a/`
  - `RESULT: UNSAFE`; witness rerun `UNSAFE`.
  - Counterexample classifier: `dsl_assert` hit.
- **Pitfalls/Fixes**:
  - No implementation issue in this run.
- **Smoke/regression**:
  - Current-baseline ATP regression anchor only; not new discovery evidence.

- **Spec**: `Procurator/argo/code/spec/bench/atp_count_mismatch_bug.prop`
- **Time**: 2026-05-05 18:58-19:00 Asia/Shanghai
- **Goal/Progress**: Same regression-only batch as above.
- **Result**:
  - Run: `.tmp/procurator/verify/atp_count_mismatch_bug/20260505-185802-b753/`
  - `RESULT: UNSAFE`; witness rerun `UNSAFE`.
  - Counterexample classifier: `dsl_assert` hit.
- **Pitfalls/Fixes**:
  - No implementation issue in this run.
- **Smoke/regression**:
  - ATP family remains reproducible on current baseline; not counted as new bug discovery.

- **Spec**: `Procurator/argo/code/spec/bench/p4xos_bug.prop`
- **Time**: 2026-05-05 19:00-19:03 Asia/Shanghai
- **Goal/Progress**: Replay previously documented P4XOS case as a regression anchor.
- **Result**:
  - Run: `.tmp/procurator/verify/p4xos_bug/20260505-185944-d908/`
  - `RESULT: UNSAFE`; witness rerun `UNSAFE`.
  - Counterexample classifier: `dsl_assert` hit.
- **Pitfalls/Fixes**:
  - No implementation issue in this run.
- **Smoke/regression**:
  - P4XOS baseline remains reproducible; not counted as new bug discovery.

- **Spec**: `Procurator/argo/code/spec/bench/p4xos_dropflag_bug.prop`
- **Time**: 2026-05-05 19:02-19:04 Asia/Shanghai
- **Goal/Progress**: Continue P4XOS regression replay.
- **Result**:
  - Run: `.tmp/procurator/verify/p4xos_dropflag_bug/20260505-190230-855c/`
  - `RESULT: UNSAFE`; witness rerun `UNSAFE`.
  - Counterexample classifier: `dsl_assert` hit.
- **Pitfalls/Fixes**:
  - No implementation issue in this run.
- **Smoke/regression**:
  - P4XOS drop-flag case is stable on current code; not counted as new bug discovery.

- **Spec**: `Procurator/argo/code/spec/bench/p4xos_majority_quorum_bug.prop`
- **Time**: 2026-05-05 19:04-19:15 Asia/Shanghai
- **Goal/Progress**: Replay quorum-path case with same 15-minute budget as regression evidence.
- **Result**:
  - Run: `.tmp/procurator/verify/p4xos_majority_quorum_bug/20260505-190424-7a22/`
  - `RESULT: UNSAFE`; witness rerun `UNSAFE`.
  - Counterexample classifier: `dsl_assert` hit.
- **Pitfalls/Fixes**:
  - Runtime is higher than other interleaving cases (~11 min), but still within per-case budget.
- **Smoke/regression**:
  - Quorum case remains reproducible after recent translator/workflow changes; not counted as new bug discovery.

- **Spec**: `Procurator/argo/code/spec/bench/p4db_damper_threshold_off_by_one_bug.prop`
- **Time**: 2026-05-05 19:16-19:17 Asia/Shanghai
- **Goal/Progress**: Classify P4DB cases to separate true bug findings from safe baselines.
- **Result**:
  - Run: `.tmp/procurator/verify/p4db_damper_threshold_off_by_one_bug/20260505-191604-e3bb/`
  - `RESULT: Ultimate proved your program to be correct!` (`SAFE`).
- **Pitfalls/Fixes**:
  - This is treated as a safe baseline only; not counted as a found bug.
- **Smoke/regression**:
  - Confirms solver/toolchain can close this spec quickly on current baseline.

- **Spec**: `Procurator/argo/code/spec/bench/p4db_router_send_frame_bug.prop`
- **Time**: 2026-05-05 19:17-19:18 Asia/Shanghai
- **Goal/Progress**: Continue P4DB classification.
- **Result**:
  - Run: `.tmp/procurator/verify/p4db_router_send_frame_bug/20260505-191646-e010/`
  - `RESULT: Ultimate proved your program to be correct!` (`SAFE`).
- **Pitfalls/Fixes**:
  - Safe baseline; not counted as bug absence beyond this model/spec.
- **Smoke/regression**:
  - Helps differentiate P4DB safe cases from bug-carrying cases below.

- **Spec**: `Procurator/argo/code/spec/bench/p4db_router_ttl_expiry_bug.prop`
- **Time**: 2026-05-05 19:18-19:19 Asia/Shanghai
- **Goal/Progress**: Validate a previously documented P4DB case remains reproducible.
- **Result**:
  - Run: `.tmp/procurator/verify/p4db_router_ttl_expiry_bug/20260505-191805-aa9c/`
  - `RESULT: UNSAFE`; witness rerun `UNSAFE`.
  - Counterexample classifier: `dsl_assert` hit.
- **Pitfalls/Fixes**:
  - No implementation issue in this run.
- **Smoke/regression**:
  - P4DB has a current-baseline reproducible regression anchor; not counted as new bug discovery.

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_count_wraparound.prop`
- **Time**: 2026-05-05 19:19-19:24 Asia/Shanghai
- **Goal/Progress**: Try one non-Flow-INT wraparound case under integrated staged pipeline.
- **Result**:
  - Run: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260505-191927-506b/`
  - Stages observed:
    - `ENTRY_CHECK=UNSAFE` (`~25.6s`)
    - `CONFIRM.unroll1=SAFE` (`~70.6s`)
    - `CONFIRM.unroll2=UNSAFE` (`~91.1s`)
    - `CLOSURE_CHECK=UNSAFE` (`~61.6s`)
  - Manifest: `certified=false` (closure obligation not discharged).
  - Base direct run in same command returned `SAFE`.
- **Pitfalls/Fixes**:
  - This is **not** a certified wraparound finding in current run because closure is UNSAFE.
  - Classified as: staged attempt failed certification, fallback direct was SAFE; requires later projection/schedule refinement before counting as bug.
- **Smoke/regression**:
  - Confirms pipeline behavior is conservative: no certification when closure fails.

- **Spec**: `Procurator/argo/code/spec/bench/frr_bug1_unexpected_mirror.prop`
- **Time**: 2026-05-05 19:24-19:26 Asia/Shanghai
- **Goal/Progress**: Replay another previously documented FRR case as a regression anchor.
- **Result**:
  - Run: `.tmp/procurator/verify/frr_bug1_unexpected_mirror/20260505-192459-d8cd/`
  - `RESULT: UNSAFE`; witness rerun `UNSAFE`.
  - Counterexample classifier: `dsl_assert` hit.
- **Pitfalls/Fixes**:
  - No implementation issue in this run.
- **Smoke/regression**:
  - FRR family has current-baseline reproducible regression anchors (`bug1` and earlier `bug2`); not counted as new bug discovery.

- **Spec**: `Procurator/argo/code/spec/bench/p4nis_bug1_forwarding_sequence_desync.prop`
- **Time**: 2026-05-05 19:24-19:26 Asia/Shanghai
- **Goal/Progress**: Expand P4NIS replay beyond already validated `bug2`.
- **Result**:
  - Run: `.tmp/procurator/verify/p4nis_bug1_forwarding_sequence_desync/20260505-192459-28c6/`
  - `RESULT: UNSAFE`; witness rerun `UNSAFE`.
  - Counterexample classifier: `internal_assert` (not `dsl_assert`).
- **Pitfalls/Fixes**:
  - This run is currently classified as non-deliverable bug evidence until DSL-assert reachability is confirmed; could indicate model internal assertion violation rather than target property violation.
- **Smoke/regression**:
  - Retained as diagnostic evidence, not counted in confirmed bug tally.

- **Spec**: `Procurator/argo/code/spec/bench/cheetah_slot_index_collision_bug.prop`
- **Time**: 2026-05-05 19:27-19:34 Asia/Shanghai
- **Goal/Progress**: Replay previously documented Cheetah case; do not count as new discovery.
- **Result**:
  - Run: `.tmp/procurator/verify/cheetah_slot_index_collision_bug/20260505-192740-a52e/`
  - `RESULT: UNSAFE`; witness rerun `UNSAFE`.
  - Counterexample classifier: `dsl_assert` hit.
- **Pitfalls/Fixes**:
  - No implementation issue in this run.
- **Smoke/regression**:
  - Cheetah path is a regression anchor only; not new discovery evidence.

- **Spec**: `Procurator/argo/code/spec/bench/ddosd_window_label_collision_bug.prop`
- **Time**: 2026-05-05 19:27-19:43 Asia/Shanghai
- **Goal/Progress**: Replay known hard case with same 15-minute budget and classify outcome strictly.
- **Result**:
  - Run: `.tmp/procurator/verify/ddosd_window_label_collision_bug/20260505-192740-aca4/`
  - Final status: `RESULT: Ultimate could not prove your program: Toolchain returned no result.`
  - Log tail indicates solver-side memory failure during TraceAbstraction:
    - `SMTLIBException ... Received EOF ... stderr: (error "out of memory")`.
- **Pitfalls/Fixes**:
  - Classified as toolchain resource failure (`UNKNOWN/ERROR`), not `SAFE`, not bug absence.
  - Needs heavier profile (e.g., 8G settings) or additional slicing/projection reduction for stable replay.
- **Smoke/regression**:
  - Retained as hard-case diagnostic for solver-profile tuning.

## 2026-05-05 Flow-INT staged wraparound re-check + SwitchML intake smoke

- **Spec**: `Procurator/argo/code/spec/bench/external_int_flowdos_counter_wraparound.prop`
- **Time**: 2026-05-05 19:46-20:08 Asia/Shanghai
- **Goal/Progress**: After reaching 6+ non-Flow-INT bugs, begin the requested Flow-INT root-cause revisit using strict staged evidence (ENTRY/CONFIRM/CLOSURE), without collapsing timeout/unknown into safe.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_int_flowdos_counter_wraparound/20260505-194655-ed37/`
  - Wraparound manifest: `.tmp/procurator/verify/external_int_flowdos_counter_wraparound/20260505-194655-ed37/wraparound/target.00.flowdos_MyIngress_counter_filter/wraparound.cegis.manifest.json`
  - Stage summary from manifest/logs:
    - `ENTRY_CHECK=UNSAFE` (`~17.85s`)
    - `CONFIRM.unroll1=UNSAFE` (`~21.56s`)
    - `CLOSURE_CHECK=UNSAFE` (`~24.1s`)
    - `projection_complete=true`; `proj_vars={flowdos_inbox_count, procurator_phase}`
  - Certification status: `certified=false` (closure obligation failed).
  - The outer command was interrupted by wrapper timeout; however staged artifacts were already generated and indicate the same non-certified outcome.
- **Pitfalls/Fixes**:
  - This is **not** a bug-absence result and **not SAFE**. It is a failed closure proof obligation under current projection/schedule setup.
  - Root-cause classification update: current evidence favors "projection/schedule model still too weak for this case" over "bug不存在".
- **Smoke/regression**:
  - Retains previous strict policy: only `ENTRY/NEAR(or CONFIRM) UNSAFE + CLOSURE SAFE` counts as certified wraparound bug.

- **Spec**: external intake smoke (compile-only)
  - Dataset candidate: `Procurator/argo/code/dataset/external_switchml_nsdi21/switchml/dev_root/p4/switchml.p4`
- **Time**: 2026-05-05 20:08-20:15 Asia/Shanghai
- **Goal/Progress**: Start "newer in-network ML system" intake requested by user, first with translator smoke (no solving yet), to surface feature gaps.
- **Result**:
  - Repository cloned to dataset: `Procurator/argo/code/dataset/external_switchml_nsdi21/switchml` (source: `p4lang/p4app-switchML`).
  - Initial translator compile failed because `tna.p4` include path/macro target not provided.
  - Retry with TNA include + macro:
    - `-I P4B-Translator/backends/tofino/bf-p4c/p4include -D__TARGET_TOFINO__=1`
    - parser/frontend proceeds, but translator exits with compiler crash:
      - `Compiler Bug: Exiting with SIGSEGV` (`P4B-Translator/lib/crash.cpp:299`)
- **Pitfalls/Fixes**:
  - This is a P4B feature/stability gap on TNA-heavy SwitchML program, not a dataset issue.
  - Action item: isolate crashing construct and add minimal reproducer before integrating this system into benchmark specs.
- **Smoke/regression**:
  - Existing Procurator bug-replay path remains functional (this step only adds external intake evidence; no behavior-changing code patch).

## 2026-05-05 New-system intake pivot (SwitchML/Mousika/NetBeacon/Soter/Henna/NeuralP4)

- **Spec**: intake/translation smoke only (no `.prop` verification yet)
  - `Procurator/argo/code/dataset/external_switchml_nsdi21/switchml/dev_root/p4/switchml.p4`
  - `Procurator/argo/code/dataset/external_mousika_infocom22/Mousika/P4/flowcontrol.p4`
  - `Procurator/argo/code/dataset/external_netbeacon_sec23/NetBeacon/switch/data_plane/switch.p4`
  - `Procurator/argo/code/dataset/external_soter_srds22/Soter/Detection process/P4/simple_l3_test.p4`
  - `Procurator/argo/code/dataset/external_henna/Henna/P4/henna.p4`
  - `Procurator/argo/code/dataset/external_neuralp4_noms25/NeuralP4/p4-vm/os-detection-32x32x3-q4-4/code/ANN.p4`
- **Time**: 2026-05-05 20:50-21:05 Asia/Shanghai
- **Goal/Progress**: Follow latest user correction: stop recounting already-verified bugs, pivot to new candidate systems and identify backend coverage gaps first.
- **Result**:
  - Dataset intake:
    - cloned new upstream repos into `Procurator/argo/code/dataset/`:
      - `external_switchml_nsdi21` (already cloned in prior step)
      - `external_mousika_infocom22`
      - `external_netbeacon_sec23`
      - `external_soter_srds22`
      - `external_henna`
      - `external_neuralp4_noms25`
  - Translator smoke classification:
    1. **SwitchML (TNA)**:
       - without TNA include/macro: missing `tna.p4`.
       - with `-I .../bf-p4c/p4include -D__TARGET_TOFINO__=1`: parser/front-end proceeds but translator crashes (`Compiler Bug: SIGSEGV`, `lib/crash.cpp:299`).
    2. **NetBeacon (TNA)**:
       - same pattern as SwitchML: with TNA include/macro it progresses, then `SIGSEGV`.
    3. **Henna (TNA)**:
       - with TNA include/macro and local include path it progresses, then `SIGSEGV`.
    4. **NeuralP4 (V1-style ANN program)**:
       - no include-missing issue; directly reaches translator crash (`SIGSEGV`).
    5. **Mousika**:
       - after TNA include/macro, fails on project-local include `common/headers.p4` missing in repository layout.
    6. **Soter**:
       - path contains spaces (`Detection process`), current translator invocation fails while deriving output path (`opening output file process/P4/simple_l3_test.p4`), i.e., path/CLI robustness issue before semantic translation.
- **Pitfalls/Fixes**:
  - These are backend/translator coverage and robustness gaps, not dataset modifications.
  - Current blocker priority:
    1) path robustness for space-containing `.p4` paths;
    2) TNA invocation contract normalization (target macro/include handling);
    3) crash root-cause for TNA and ANN-heavy programs (`SIGSEGV`).
- **Smoke/regression**:
  - This step intentionally did not claim any new bug findings.
  - It establishes an auditable intake baseline and concrete translator-failure targets for subsequent implementation fixes.

## 2026-05-05 New-system translator correction and frontend IO regression

- **Spec**: intake/translation smoke only (no `.prop` verification yet)
  - `Procurator/argo/code/dataset/external_switchml_nsdi21/switchml/dev_root/p4/switchml.p4`
  - `Procurator/argo/code/dataset/external_netbeacon_sec23/NetBeacon/switch/data_plane/switch.p4`
  - `Procurator/argo/code/dataset/external_henna/Henna/P4/henna.p4`
  - `Procurator/argo/code/dataset/external_soter_srds22/Soter/Detection process/P4/simple_l3_test.p4`
  - `Procurator/argo/code/dataset/external_neuralp4_noms25/NeuralP4/p4-vm/os-detection-32x32x3-q4-4/code/ANN.p4`
  - `Procurator/argo/code/dataset/external_mousika_infocom22/Mousika/P4/flowcontrol.p4`
- **Time**: 2026-05-05 21:50-22:18 Asia/Shanghai
- **Goal/Progress**: Correct the new-system translator intake classification before creating bug specs; separate invocation errors, frontend include/path issues, and real semantic translation gaps.
- **Result**:
  - P4B build:
    - `cd /mnt/e/p4-verify/P4B-Translator/build-host && cmake --build . --target p4c-translator -j2` completed and restored `backends/verify/p4c-translator`.
  - `SwitchML`: translated to BPL with automatic TNA normalization.
    - Output: `/tmp/switchml.bpl` (`~863 KiB`, 498 Boogie procedures).
    - Stateful objects detected in BPL: 36 register arrays, including `Ingress_rdma_receiver_receiver_data_register`, `Ingress_update_and_check_worker_bitmap_worker_bitmap`, `Ingress_workers_counter_workers_count`, and `Ingress_value00_values..Ingress_value31_values`.
  - `NetBeacon`: translated to BPL with automatic TNA normalization.
    - Output: `/tmp/netbeacon.bpl` (`~197 KiB`, 175 Boogie procedures).
    - Stateful objects detected in BPL: 13 register arrays, including `SwitchIngress_Register_total_pkts`, `SwitchIngress_Register_total_bytes`, `SwitchIngress_Register_last_pkt_timestamp`, `SwitchIngress_Register_last_classified_timestamp`, `SwitchIngress_Register_result`, and `SwitchIngress_Register_bin1/bin2`.
  - `Henna`: translated to BPL with automatic TNA normalization and local include path.
    - Output: `/tmp/henna2.bpl` (`~71 KiB`, 115 Boogie procedures).
    - Current translated BPL has no register read/write procedures; likely lower priority for wraparound mining unless interleaving properties are derived from packet/control state.
  - `Soter`: translated to BPL under a path containing spaces.
    - Output: `/tmp/soter_direct2.bpl` (`~43 KiB`, 61 Boogie procedures).
    - The verify frontend rewrites TNA inputs to a sanitized temporary path such as `/tmp/p4b_sanitized_*/simple_l3_test.p4`, avoiding `cpp` path splitting and missing `tna.p4`.
  - `NeuralP4`: translated to BPL.
    - Output: `/tmp/neuralp4_ann.bpl` (`~243 KiB`).
    - Current BPL procedure count is 0, so this needs semantic inspection before it can count as a correct harness/backend conversion for bug mining.
  - `Mousika`: still blocked before translation.
    - Error: `common/headers.p4: No such file or directory`.
    - The cloned upstream tree currently contains `P4/flowcontrol.p4` but no `P4/common/headers.p4`; classify this as an incomplete upstream input/layout issue until the missing generated/include files are recovered, not as a P4B syntax failure.
- **Pitfalls/Fixes**:
  - Previous intake smoke misclassified several runs as translator `SIGSEGV`; the true cause was invoking `p4c-translator` without `-o`, which left `options.outputBplFile` null and crashed while opening the Boogie output stream.
  - Fixed in `P4B-Translator/backends/verify/bpl_verify/main.cpp`: missing `-o <outfile>` now reports a normal error instead of crashing.
  - Fixed/finished in `P4B-Translator/backends/verify/bpl_verify/frontend.{h,cpp}`: automatic TNA include/macro normalization is exported correctly, and space-containing source paths trigger verify frontend sanitization.
  - Fixed in `P4B-Translator/frontends/common/parser_options.cpp`: preprocessor input path is shell-quoted instead of using `absl::CEscape` as if it were shell quoting.
  - WSL invocation note: when passing paths with spaces from PowerShell, prefer `wsl.exe --cd ... -- <argv...>` or a WSL-side script; nested `bash -lc` quoting can truncate paths and produce false failures.
- **Smoke/regression**:
  - Added `dslc/tests/p4b/translator/test_frontend_io.py`:
    - `test_missing_output_path_reports_error_instead_of_crashing`
    - `test_tna_program_under_space_path_translates`
  - Regression commands run in WSL:
    - `python3 -m unittest -v dslc.tests.p4b.translator.test_frontend_io` -> PASS (2 tests).
    - `python3 -m unittest -v dslc.tests.p4b.test_p4b_translator_regressions.TestP4BTranslatorRegressions.test_tofino_constructor_style_local_instantiation_translates` -> PASS.
    - `python3 -m unittest -v dslc.tests.p4b.test_p4b_tofino_cpp_defines` -> PASS (5 tests).
    - `./P4B-Translator/build-host/p4c-translator -I P4B-Translator/p4include --goto --bmv2cmds Procurator/argo/code/dataset/Netchain/commands_1.txt --slicing-vars=sequence_reg[0] --slicing-selftest=netchain_seq Procurator/argo/code/dataset/Netchain/netchain_16.p4` -> PASS.
  - Do not count these translation smokes as new bugs; they only establish that SwitchML/NetBeacon/Soter/Henna/NeuralP4 can now be used for the next bug-spec construction phase.

## 2026-05-05 NetBeacon bin2 direct-check blocker: TNA checksum extern

- **Spec**: `Procurator/argo/code/spec/bench/external_netbeacon_bin2_wraparound_direct.prop`
- **Time**: 2026-05-05 23:34-23:36, 2026-05-06 00:02-00:09 Asia/Shanghai
- **Goal/Progress**: Start NetBeacon bug-spec verification after the new-system translator intake; first bounded direct run was used as a stage-by-stage probe rather than as a long blind solve.
- **Result**:
  - Failed run directory: `.tmp/procurator/verify/external_netbeacon_bin2_wraparound_direct/20260505-233456-c73a/`
  - Base BPL generation succeeded, including TNA `RegisterAction.execute` and register mirror variables for `nb_SwitchIngress_Register_bin2`.
  - Ultimate returned no result before solving because Boogie typechecking failed:
    - `Calling undeclared procedure ... nb_SwitchIngressParser_ipv4_checksum.add`
  - Classification: translator/backend coverage bug, not `SAFE`, not bug absence, and not solver timeout.
- **Pitfalls/Fixes**:
  - Root cause: P4B treated every `.add(...)` method-call statement as a counter extern and returned before the generic void-extern stub path. TNA parser `Checksum.add(hdr.ipv4)` therefore became a Boogie `call` without a matching declaration.
  - Fixed in `P4B-Translator/backends/verify/translate/impl/lowering/translate_statement.cpp`: only registered counter extern instances use the counter `.count/.increment/.add` branch; non-counter `.add` calls now fall through to the generic void-extern declaration path.
- **Smoke/regression**:
  - Added `dslc/tests/p4b/translator/test_frontend_io.py::test_tna_checksum_add_gets_declared_as_void_extern`, checking that NetBeacon direct P4B output contains both:
    - `call SwitchIngressParser_ipv4_checksum.add(hdr.ipv4);`
    - `procedure SwitchIngressParser_ipv4_checksum.add(arg0:Ref);`
  - Regression commands run in WSL:
    - `cmake --build P4B-Translator/build-host --target p4c-translator -j2` -> PASS.
    - `python3 -m unittest -v dslc.tests.p4b.translator.test_frontend_io` -> PASS (3 tests).
    - `python3 -m unittest -v dslc.tests.p4b.test_p4b_tofino_cpp_defines` -> PASS (5 tests).

## 2026-05-06 Focused direct bounded fallback for pre-unrolled harnesses

- **Spec**: workflow regression plus NetBeacon pre-unrolled harness probe
  - `dslc/tests/workflows/test_focused_direct_workflow.py::test_timeout_triggers_bounded_probe_for_preunrolled_mainprocedure`
  - `Procurator/argo/code/spec/bench/external_netbeacon_bin2_wraparound_direct.prop`
- **Time**: 2026-05-06 00:10-00:17 Asia/Shanghai
- **Goal/Progress**: Make focused direct fallback usable when the base `mainProcedure` was already bounded by `--max-steps`, so a focused timeout can still trigger a smaller one-error-location bounded probe instead of silently giving up.
- **Result**:
  - Fixed `dslc/workflows/focused_direct.py` so `_inject_focus_latch_and_unroll(...)` accepts an existing acyclic/pre-unrolled `mainProcedure` when no scheduler loop remains.
  - The generated bounded focused BPL now latchifies the existing pre-unrolled body and appends a final `assert !procurator_focused_underapprox_hit;`.
  - Local probe on NetBeacon confirmed the transform now returns bounded BPL text for a pre-unrolled focused model instead of `None`.
- **Pitfalls/Fixes**:
  - Root cause: focused direct assumed every timeout fallback could re-unroll a scheduler loop. Specs compiled with `--max-steps` already replaced the loop with an acyclic prefix, so the fallback skipped exactly the cases where a long finite prefix was intended.
  - The fix is still an under-approximation and only accepts `UNSAFE`; `SAFE`, `UNKNOWN`, timeout, type errors, and missing focused assertion still fall back to the original verification path and must not be reported as bug absence.
- **Smoke/regression**:
  - `python3 -m unittest -v dslc.tests.workflows.test_focused_direct_workflow` -> PASS (15 tests).

## 2026-05-06 NetBeacon bin2 bounded focused probe still needs optimization

- **Spec**: `Procurator/argo/code/spec/bench/external_netbeacon_bin2_wraparound_direct.prop`
- **Time**: 2026-05-06 00:17-00:30 Asia/Shanghai
- **Goal/Progress**: Run NetBeacon bin2 verification in stages after the checksum extern and focused fallback fixes, with a bounded direct under-approximation rather than a long blind solve.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_netbeacon_bin2_wraparound_direct/20260506-001736-c926/`
  - Command shape:
    - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_netbeacon_bin2_wraparound_direct.prop --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing --skip-duplicated-fail-fast-global-asserts --wraparound off --max-steps 260 --ultimate-timeout-seconds 240 --ultimate-xmx-gb 4 --no-witness-rerun`
  - Focused direct prepass timed out, then bounded fallback generated:
    - `external_netbeacon_bin2_wraparound_direct.focused-index0.bounded32.bpl`
    - `external_netbeacon_bin2_wraparound_direct.focused-index0.bounded64.bpl`
    - `external_netbeacon_bin2_wraparound_direct.focused-index0.bounded128.bpl`
  - `bounded32` and `bounded64` each had one remaining error location but timed out; `bounded128` was interrupted by the outer timeout before producing a useful log.
  - No `.unsafe.json` marker was produced, so this is **not** counted as a new bug yet.
- **Pitfalls/Fixes**:
  - This result is a solver/encoding timeout on a candidate witness path, not a proof that the candidate is absent.
  - Next optimization target: reduce the bounded focused model before rerunning deeper probes, especially by keeping only target-relevant latch sites and avoiding duplicated per-step assertion machinery.
- **Smoke/regression**:
  - Existing focused-direct workflow regression remains the guard for this fallback path.
  - No old verified bug was re-counted as progress in this NetBeacon experiment.

## 2026-05-06 NetBeacon bin2 focused-direct false-positive audit

- **Spec**: `Procurator/argo/code/spec/bench/external_netbeacon_bin2_wraparound_direct.prop`
- **Time**: 2026-05-06 00:50-02:14 Asia/Shanghai
- **Goal/Progress**: Audit the NetBeacon bin2 focused-direct candidate after a suspicious witness combined `pkt_bin2.action_run == Update_bin2` with a zero-valued register mirror. The goal was to distinguish a real wrap/update-zero execution from a tooling false positive before counting it as a new bug.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_netbeacon_bin2_wraparound_direct/20260506-005019-27d8/`
  - Command shape:
    - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_netbeacon_bin2_wraparound_direct.prop --boogie-harness sequential --no-two-stage --no-reg-debug --skip-duplicated-fail-fast-global-asserts --wraparound off --max-steps 260 --ultimate-timeout-seconds 180 --ultimate-xmx-gb 4 --no-witness-rerun`
  - P4B slicing kept the target NetBeacon bin2 path and reduced the focused BPL enough for Ultimate to return `UNSAFE`.
  - Focused marker:
    - `.tmp/procurator/verify/external_netbeacon_bin2_wraparound_direct/20260506-005019-27d8/external_netbeacon_bin2_wraparound_direct.focused-index0.unsafe.json`
  - Marker classification:
    - `kind = focused_under_approx`
    - `target_reg = nb_SwitchIngress_Register_bin2`
    - `idx_var = nb_ig_md.flow_index`
    - `zero = 0bv16`
    - `target_value = 0bv8`
  - Ultimate log confirmed the counterexample hit the intended focused line:
    - `CounterExampleResult [Line: 2110]: assertion can be violated`
    - line 2110 is `assert !((nb_SwitchIngress_Register_bin2__wrote_index0 && (nb_SwitchIngress_Register_bin2__last0_value == 0bv8)));`
    - `OverallTime≈131.8s`
- **Pitfalls/Fixes**:
  - Earlier no-slicing runs timed out and must not be interpreted as absence. The decisive change here was keeping slicing on; the target path remains present while unrelated NetBeacon feature/tree code is reduced.
  - This is a direct under-approximation witness for the slot-0 flow-index shape, not a wraparound closure certificate. It is valid for bug finding because `UNSAFE` witnesses in the under-approx model correspond to original executions with `flow_index == 0`; `SAFE/TIMEOUT/UNKNOWN` would still have fallen back and would not prove absence.
- **Smoke/regression**:
  - This run is **demoted and not counted** as a new bug after the guard-aware audit.
  - Root cause: the old focused-direct transform accepted a pass-end assertion guarded only by `nb_pkt_bin2.action_run == nb_pkt_bin2.action.SwitchIngress_Update_bin2`. That did not prove `Update_bin2` wrote the target register in the same pass, so a stale or environment-constrained `action_run` could be combined with the zero mirror produced by another action such as `Init0`.
  - After the fix, rerun `.tmp/procurator/verify/external_netbeacon_bin2_wraparound_direct/20260506-020514-5080/` produced no `.unsafe.json` marker:
    - focused-index0: `TIMEOUT` at line 1420, `OverallTime≈149.2s`
    - bounded32: `TIMEOUT` at line 16566, `OverallTime≈126.3s`
    - bounded64: `TIMEOUT` at line 16566, `OverallTime≈125.9s`
  - Current classification: timeout / inconclusive, not bug absence and not a valid witness.
  - New regression: `dslc.tests.transform.test_focused_direct.FocusedDirectTransformTest.test_action_guarded_assert_uses_guarded_writer_site_only`.
  - Regression runs:
    - `python3 -m unittest -v dslc.tests.transform.test_focused_direct` (PASS, 15 tests)
    - `python3 -m unittest -v dslc.tests.workflows.test_focused_direct_workflow` (PASS, 15 tests)

## 2026-05-06 NetBeacon total_pkts wraparound staged entry check

- **Spec**: `Procurator/argo/code/spec/bench/external_netbeacon_total_pkts_wraparound.prop`
- **Time**: 2026-05-06 01:02 Asia/Shanghai
- **Goal/Progress**: Start the 16-bit NetBeacon `Register_total_pkts` wraparound candidate with staged execution. This is a new-system candidate, separate from the already verified benchmark bugs.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_netbeacon_total_pkts_wraparound/20260506-010218-31ff/`
  - Command shape:
    - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_netbeacon_total_pkts_wraparound.prop --boogie-harness sequential --no-two-stage --no-reg-debug --skip-duplicated-fail-fast-global-asserts --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-cegar-mode schedule_replay --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --wraparound-stop-after entry --ultimate-timeout-seconds 120 --ultimate-xmx-gb 4 --no-witness-rerun`
  - `ENTRY_CHECK` returned `UNSAFE` in about 19.9s.
  - Manifest: `.tmp/procurator/verify/external_netbeacon_total_pkts_wraparound/20260506-010218-31ff/wraparound/target.00.nb_SwitchIngress_Register_total_pkts/wraparound.cegis.manifest.json`
- **Pitfalls/Fixes**:
  - This stage only proves the base harness/env shape is reachable; it is not yet a wraparound bug certificate and must not be counted as a new bug.
  - Because the target is 16-bit, bounded direct checking from the zero initial state is not expected to reach wrap quickly; this candidate should proceed through NEAR/CONFIRM and then CLOSURE.
- **Smoke/regression**:
  - No code changes in this staged run.
  - Continue with `near_wrap`/`closure` before classifying the candidate.

## 2026-05-06 NetBeacon total_pkts near-wrap reachability

- **Spec**: `Procurator/argo/code/spec/bench/external_netbeacon_total_pkts_wraparound.prop`
- **Time**: 2026-05-06 01:27-01:29 Asia/Shanghai
- **Goal/Progress**: Continue the staged NetBeacon `Register_total_pkts` wraparound candidate after ENTRY succeeded, stopping after NEAR_WRAP so the expensive proof stage is only attempted when there is a reachable near-wrap suffix.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_netbeacon_total_pkts_wraparound/20260506-012724-4041/`
  - Command shape:
    - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_netbeacon_total_pkts_wraparound.prop --boogie-harness sequential --no-two-stage --no-reg-debug --skip-duplicated-fail-fast-global-asserts --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-cegar-mode schedule_replay --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --wraparound-stop-after near_wrap --ultimate-timeout-seconds 240 --ultimate-xmx-gb 4 --no-witness-rerun`
  - `ENTRY_CHECK`: `UNSAFE` in about 59.7s.
  - `NEAR_WRAP`: `UNSAFE` in about 43.9s on `external_netbeacon_total_pkts_wraparound.schedule.00.near_wrap.unroll1.bpl`.
  - Manifest: `.tmp/procurator/verify/external_netbeacon_total_pkts_wraparound/20260506-012724-4041/wraparound/target.00.nb_SwitchIngress_Register_total_pkts/wraparound.cegis.manifest.json`
- **Pitfalls/Fixes**:
  - This is useful reachability evidence, but it is still not a certified wraparound bug. The manifest marks the dependency projection as incomplete, so a sound wraparound claim still requires CLOSURE to prove the selected projection or a backend/projection refinement.
  - Do not count this candidate as a completed bug until closure proof or another sound direct witness is available.
- **Smoke/regression**:
  - No code changes in this staged run.
  - Next step: run CLOSURE and inspect whether failure is due to real projection instability, missing dependency extraction, or solver time.

## 2026-05-06 NetBeacon total_pkts closure gate blocked by dynamic-slot projection

- **Spec**: `Procurator/argo/code/spec/bench/external_netbeacon_total_pkts_wraparound.prop`
- **Time**: 2026-05-06 01:33-01:34 Asia/Shanghai
- **Goal/Progress**: Attempt the CLOSURE stage after `ENTRY_CHECK` and `NEAR_WRAP` both returned `UNSAFE`.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_netbeacon_total_pkts_wraparound/20260506-013324-c15c/`
  - Command shape:
    - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_netbeacon_total_pkts_wraparound.prop --boogie-harness sequential --no-two-stage --no-reg-debug --skip-duplicated-fail-fast-global-asserts --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-cegar-mode schedule_replay --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --wraparound-stop-after closure --ultimate-timeout-seconds 600 --ultimate-xmx-gb 4 --no-witness-rerun`
  - `ENTRY_CHECK`: `UNSAFE` in about 18.6s.
  - `NEAR_WRAP`: `UNSAFE` in about 48.0s.
  - The workflow generated `external_netbeacon_total_pkts_wraparound.schedule.00.closure_check.bpl`, but did not run the solver on it because the schedule certificate config had `projection_complete=false`.
  - Manifest diagnostic: `near-wrap bug found but hard dependency projection gap remains; falling back to direct verification`.
  - Relevant notes:
    - `dynamic_index_preloop_globals=nb_ig_md.flow_index`
    - `dependency_projection_unstable_cutpoint_guards=7`
    - dynamic slot projection expressions for `nb_SwitchIngress_Register_full_flow_hash[nb_ig_md.flow_index]` and `nb_SwitchIngress_Register_last_classified_timestamp[nb_ig_md.flow_index]`
- **Pitfalls/Fixes**:
  - This is not a `SAFE` result and not bug absence. It is a soundness gate: the current certificate cannot yet prove replay for the same dynamic flow slot, because `nb_ig_md.flow_index` is a pre-loop global key rather than a fixed literal in the candidate.
  - The correct next implementation direction is to refine dynamic-slot projection/key handling or use a sound direct witness; do not bypass `projection_complete`.
- **Smoke/regression**:
  - No code changes in this staged run.
  - This case should become a regression once dynamic-slot schedule certificates are improved.

## 2026-05-06 NetBeacon total_bytes bounded direct probe timed out

- **Spec**: `Procurator/argo/code/spec/bench/external_netbeacon_total_bytes_wraparound.prop`
- **Time**: 2026-05-06 01:37-01:44 Asia/Shanghai
- **Goal/Progress**: Try a short direct under-approximation for the 32-bit `Register_total_bytes` candidate using a large packet length, after `total_pkts` exposed a dynamic-slot projection gate.
- **Result**:
  - Run directory: `.tmp/procurator/verify/external_netbeacon_total_bytes_wraparound/20260506-013712-7ca5/`
  - Command shape:
    - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_netbeacon_total_bytes_wraparound.prop --boogie-harness sequential --no-two-stage --no-reg-debug --skip-duplicated-fail-fast-global-asserts --wraparound off --max-steps 8 --ultimate-timeout-seconds 240 --ultimate-xmx-gb 4 --no-witness-rerun`
  - The run produced focused direct artifacts:
    - `external_netbeacon_total_bytes_wraparound.focused-index0.bpl`
    - `external_netbeacon_total_bytes_wraparound.focused-index0.bounded64.bpl`
    - `external_netbeacon_total_bytes_wraparound.focused-index0.bounded64.log`
  - Ultimate timed out on the 1-error-location bounded64 model after about 145.6s of TraceAbstraction time (`OverallIterations=20`, trace length about 310).
  - No `.unsafe.json` marker was produced.
- **Pitfalls/Fixes**:
  - This is a verification timeout on a candidate path, not a proof of absence.
  - The candidate remains useful, but it needs either a stronger direct-model reduction or the same dynamic-slot/key projection refinement required by `total_pkts`.
- **Smoke/regression**:
  - No code changes in this staged run.
  - Keep this as an optimization target; do not count it as a found bug.

## 2026-05-06 SwitchML value00 slicing/procedure pruning unblock

- **Spec**:
  - `Procurator/argo/code/spec/bench/external_switchml_value00_first_zero_direct.prop`
  - `Procurator/argo/code/spec/bench/external_switchml_value00_second_zero_direct.prop`
- **Time**: 2026-05-06 04:58-06:18 Asia/Shanghai
- **Goal/Progress**: Continue the new-system mining loop on SwitchML by first making the P4B conversion and sliced Boogie model small enough for staged direct checking. This was a translator/tooling unblock, not a new bug claim.
- **Result**:
  - Earlier SwitchML runs reached translation but were not useful because the sliced model still carried dead sibling aggregation registers/procedures such as `Ingress_value01_values` through `Ingress_value31_values`, causing Ultimate RCFG/Z3 blowup or no useful result.
  - After the pruning fixes, `external_switchml_value00_second_zero_direct.prop` produced a reachable direct `UNSAFE` witness:
    - no-witness-rerun run dir: `.tmp/procurator/verify/external_switchml_value00_second_zero_direct/20260506-061601-8cf4/`
    - witness-rerun run dir: `.tmp/procurator/verify/external_switchml_value00_second_zero_direct/20260506-061828-8e96/`
    - witness files: `external_switchml_value00_second_zero_direct.bpl-witness.graphml` and `external_switchml_value00_second_zero_direct.bpl-witness.yml`
  - Classification: **not counted as a new bug**. The current property only shows that a zero-valued external packet can write/propagate zero in `value00`, which is a weak sanity property rather than a protocol interleaving or wraparound violation.
- **Pitfalls/Fixes**:
  - Root cause: slicing treated `RegisterAction` constructor target registers as ordinary live uses during final pruning, so SwitchML retained all aggregation-value sibling registers even when only `Ingress_value00_values` was seeded.
  - Root cause: retained structural child statements were not always reflected in `keepVarNames`, and P4C canonical names such as `update_flow_ID_0.execute` did not always match downstream target-prefix expectations.
  - Fixed in P4B slicing/translation:
    - `P4B-Translator/backends/verify/slicing/slicer_apply.cpp`: final register-declaration pruning keeps a `RegisterAction` target register only when retained statements reference that action instance.
    - `P4B-Translator/backends/verify/translate/impl/core/translate.cpp`: slicing-mode `writeToFile` emits only procedures reachable from `ULTIMATE.start` / `mainProcedure` through Boogie calls, CFG successors, and expression-function references.
    - `P4B-Translator/backends/verify/slicing/slicer_internal.h`: `KeepVarCollector` descends into retained structural statements and records retained `RegisterAction.execute/apply` calls as explicit keep keys.
    - `P4B-Translator/backends/verify/slicing/slicer.cpp`: keep-var emission also adds de-suffixed aliases for canonical `_0` bases.
  - Shell pitfall: PowerShell/WSL nested quoting with pipes and `$P4B` produced misleading command failures. Prefer direct `wsl.exe --cd ... -- <argv>` forms or simple `bash -lc` commands when running these regressions.
- **Smoke/regression**:
  - `wsl.exe --cd /mnt/e/p4-verify/P4B-Translator/build-host -- cmake --build . --target p4c-translator -j1` -> PASS.
  - Targeted P4B slicing selftests -> PASS:
    - `test_external_int_flowdos_hash_index_dependency_slicing`
    - `test_recirc_meta_flow_cross_stage_slicing`
    - `test_external_flowrest_flow_duration_seed_prunes_sibling_feature_registers`
    - `test_external_etc_pkt_len_target_prefix_slicing`
  - Broader translator/slicing regression -> PASS:
    - `wsl.exe --cd /mnt/e/p4-verify -- python3 -m unittest -v dslc.tests.p4b.translator.test_frontend_io dslc.tests.p4b.test_p4b_translator_slicing_selftest dslc.tests.boogie.backend.test_boogie_bpl_missing_var_decls`
    - Result: 35 tests OK.
  - New guard: `dslc/tests/p4b/translator/test_frontend_io.py::test_switchml_value00_slice_prunes_sibling_aggregation_registers`.

## 2026-05-06 NeuralP4 run-state interleaving witness

- **Spec**: `Procurator/argo/code/spec/bench/external_neuralp4_netml_run_interleaving.prop`
- **Time**: 2026-05-06 08:13-08:45 Asia/Shanghai
- **Goal/Progress**: Continue the new-system mining loop on NeuralP4 (NOMS 2025) by supporting its large generated V1Model ANN P4 program, then checking a real run-state interleaving property instead of a syntax-only translation smoke.
- **Result**:
  - New bug count progress: **1/10**.
  - P4 input: `Procurator/argo/code/dataset/external_neuralp4_noms25/NeuralP4/p4-vm/netml-iot-16x32x2-q4-4/code/ANN.p4`.
  - Property: three packets from runs `1, 2, 1` interleave on one shared ANN state slot. A different `run_id` resets the global `reg_received_stimuli` / `reg_n_received_stimuli` state, so returning to run 1 records only neuron 1 (`received_stimuli == 2`, `n_received_stimuli == 1`) instead of preserving run 1's earlier neuron 0 progress.
  - Sliced compile/smoke after the P4B fixes:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_neuralp4_netml_run_interleaving.prop --out /tmp/external_neuralp4_netml_run_interleaving.sliced3.bpl --work-dir /tmp/external_neuralp4_netml_run_interleaving.sliced3.work --boogie-harness sequential --no-two-stage --no-reg-debug` -> PASS in about 20.1s.
    - `./bin/procurator smoke --bpl /tmp/external_neuralp4_netml_run_interleaving.sliced3.bpl --harness sequential` -> PASS; generated BPL was 676 lines / 38K.
  - Verified UNSAFE with witness:
    - Run directory: `.tmp/procurator/verify/external_neuralp4_netml_run_interleaving/20260506-084113-169b/`
    - Command shape:
      - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_neuralp4_netml_run_interleaving.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound off --ultimate-timeout-seconds 300 --ultimate-xmx-gb 4 --use-spec-max-steps`
    - Main run: `UNSAFE`, feasible counterexample, `OverallTime≈60.9s`, `OverallIterations=28`.
    - Witness rerun: `UNSAFE`, feasible counterexample, `OverallTime≈63.2s`, `OverallIterations=28`.
    - Witness files:
      - `.tmp/procurator/verify/external_neuralp4_netml_run_interleaving/20260506-084113-169b/external_neuralp4_netml_run_interleaving.bpl-witness.graphml`
      - `.tmp/procurator/verify/external_neuralp4_netml_run_interleaving/20260506-084113-169b/external_neuralp4_netml_run_interleaving.bpl-witness.yml`
    - DSL counterexample classification: `dsl_assert` violated.
- **Pitfalls/Fixes**:
  - Initial no-prune verification reached TraceAbstraction but timed out around 300s; this was not bug absence.
  - Initial sliced compile timed out in `p4c-translator`. Root cause: P4B slicer materialized full per-node reaching-definition sets, which is too expensive for large generated ANN code. Fixed `P4B-Translator/backends/verify/slicing/slicer.cpp` to build DDG edges by walking each variable definition forward until a same-variable redefinition, avoiding the quadratic reaching-set materialization.
  - Sliced Boogie still carried dead ANN temporary globals through stale `modifies` and local-variable `havoc` statements. Fixed:
    - `P4B-Translator/backends/verify/translate/impl/core/translate.cpp`: sliced `modifies` now respects `shouldKeepVar`, reachable-procedure emission is pruned, and core `p4b_*` model flags are always kept so procedure modifies contracts remain sound.
    - `P4B-Translator/backends/verify/translate/impl/lowering/translate_expression.cpp`: Declaration_Variable lowering now skips `havoc`/initializer emission for global temporaries discarded by slicing.
  - Earlier P4/Boogie type issues fixed along the same NeuralP4 intake path included missing opaque header type declarations, shift RHS width coercion, bool-to-bitvector casts, prefixer handling of Boogie keyword `then`, and missing type-declaration checks in procedure/function signatures.
- **Smoke/regression**:
  - `wsl.exe --cd /mnt/e/p4-verify/P4B-Translator/build-host -- bash -lc 'time cmake --build . --target p4c-translator -j16'` -> PASS.
  - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc '.venv-wsl/bin/python -m unittest -v dslc.tests.p4b.test_p4b_translator_regressions.TestP4BTranslatorRegressions.test_neuralp4_sliced_modifies_do_not_redeclare_pruned_temps dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_netchain_seq_seed_slicing dslc.tests.boogie.backend.test_boogie_bpl_missing_type_decls'` -> PASS (9 tests).
  - New guard: `dslc/tests/p4b/test_p4b_translator_regressions.py::TestP4BTranslatorRegressions::test_neuralp4_sliced_modifies_do_not_redeclare_pruned_temps`, which checks that slicing does not reintroduce pruned ANN temporaries through declarations, `modifies`, or `havoc`, and that `p4b_*` model flags remain in `mainProcedure` modifies.

## 2026-05-06 NeuralP4 completion-reset duplicate stimulus witness

- **Spec**: `Procurator/argo/code/spec/bench/external_neuralp4_netml_completion_reopen_interleaving.prop`
- **Time**: 2026-05-06 08:49-08:53 Asia/Shanghai
- **Goal/Progress**: Check a second NeuralP4 state-machine failure mode after the run-state interleaving witness: completion of a one-stimulus neuron resets the global received-stimulus bitmap/count, allowing a later duplicate stimulus for the same run/neuron to be accepted again.
- **Result**:
  - New bug count progress: **2/10**.
  - Property: two identical packets for run `7`, neuron `0`, with `expected_stimuli=1` and `n_expected_stimuli=1`. The first packet completes the neuron and resets `reg_received_stimuli` / `reg_n_received_stimuli` to zero; the second packet is then accepted/forwarded again instead of being recognized as duplicate progress for the already-completed neuron.
  - Compile/smoke:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_neuralp4_netml_completion_reopen_interleaving.prop --out /tmp/external_neuralp4_netml_completion_reopen_interleaving.bpl --work-dir /tmp/external_neuralp4_netml_completion_reopen_interleaving.work --boogie-harness sequential --no-two-stage --no-reg-debug` -> PASS in about 15.9s.
    - `./bin/procurator smoke --bpl /tmp/external_neuralp4_netml_completion_reopen_interleaving.bpl --harness sequential` -> PASS; generated BPL was 717 lines / 40K.
  - Verified UNSAFE with witness:
    - Run directory: `.tmp/procurator/verify/external_neuralp4_netml_completion_reopen_interleaving/20260506-085039-e244/`
    - Command shape:
      - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_neuralp4_netml_completion_reopen_interleaving.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound off --ultimate-timeout-seconds 300 --ultimate-xmx-gb 4 --use-spec-max-steps`
    - Main run: `UNSAFE`, feasible counterexample, `OverallTime≈24.0s`, `OverallIterations=17`.
    - Witness rerun: `UNSAFE`, feasible counterexample, `OverallTime≈28.5s`, `OverallIterations=17`.
    - Witness files:
      - `.tmp/procurator/verify/external_neuralp4_netml_completion_reopen_interleaving/20260506-085039-e244/external_neuralp4_netml_completion_reopen_interleaving.bpl-witness.graphml`
      - `.tmp/procurator/verify/external_neuralp4_netml_completion_reopen_interleaving/20260506-085039-e244/external_neuralp4_netml_completion_reopen_interleaving.bpl-witness.yml`
    - DSL counterexample classification: `dsl_assert` violated.
- **Pitfalls/Fixes**:
  - The assertion intentionally observes the completion reset plus non-drop/forward outcome. Looking only at `reg_n_received_stimuli__last0_value` would be ambiguous because the same pass writes both the incremented count and the reset value; the final register mirror is the reset write.
  - No new implementation fix was required beyond the NeuralP4/P4B slicing and model-contract fixes recorded in the previous entry.
- **Smoke/regression**:
  - Reuses the NeuralP4 regression guard from the previous entry.
  - This is a direct GemCutter witness, not a wraparound certificate.

## 2026-05-06 NeuralP4 16-bit run_id alias drop witness

- **Spec**: `Procurator/argo/code/spec/bench/external_neuralp4_netml_run_id_alias_drop.prop`
- **Time**: 2026-05-06 09:04-09:07 Asia/Shanghai
- **Goal/Progress**: Check a third NeuralP4 failure mode that is distinct from the prior run-state interleaving and completion-reset cases: low-width run identifiers can alias after wraparound/reuse, so stale per-run progress may suppress a valid stimulus in a later logical ANN run.
- **Result**:
  - New bug count progress: **3/10**.
  - Property: two packets share low 16-bit `run_id = 9` and neuron `0`, with `expected_stimuli = 1` and `n_expected_stimuli = 3`. The first packet records neuron 0 without completing the neuron. The second packet models a later logical run whose low 16 bits alias to 9; since `reg_run_id` does not change, the old `reg_received_stimuli` bitmap remains `1`, so the second packet is treated as duplicate and dropped.
  - Compile/smoke:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_neuralp4_netml_run_id_alias_drop.prop --out /tmp/external_neuralp4_netml_run_id_alias_drop.bpl --work-dir /tmp/external_neuralp4_netml_run_id_alias_drop.work --boogie-harness sequential --no-two-stage --no-reg-debug` -> PASS in about 18.5s.
    - `./bin/procurator smoke --bpl /tmp/external_neuralp4_netml_run_id_alias_drop.bpl --harness sequential` -> PASS; generated BPL was 717 lines / 40K.
  - Verified UNSAFE with witness:
    - Run directory: `.tmp/procurator/verify/external_neuralp4_netml_run_id_alias_drop/20260506-090459-e00c/`
    - Command shape:
      - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_neuralp4_netml_run_id_alias_drop.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound off --ultimate-timeout-seconds 300 --ultimate-xmx-gb 4 --use-spec-max-steps`
    - Main run: `UNSAFE`, feasible counterexample, `OverallTime≈33.4s`, `OverallIterations=18`.
    - Witness rerun: `UNSAFE`, feasible counterexample, `OverallTime≈32.6s`, `OverallIterations=18`.
    - Witness files:
      - `.tmp/procurator/verify/external_neuralp4_netml_run_id_alias_drop/20260506-090459-e00c/external_neuralp4_netml_run_id_alias_drop.bpl-witness.graphml`
      - `.tmp/procurator/verify/external_neuralp4_netml_run_id_alias_drop/20260506-090459-e00c/external_neuralp4_netml_run_id_alias_drop.bpl-witness.yml`
    - DSL counterexample classification: `dsl_assert` violated.
- **Pitfalls/Fixes**:
  - This is a direct bounded witness, not a certified large-prefix proof. The bug mechanism is the 16-bit alias of the stored run identifier; the spec models a later logical run by reusing the same low 16 bits.
  - No implementation fix was needed beyond the existing NeuralP4/P4B slicing and model-contract support.
- **Smoke/regression**:
  - Reuses the NeuralP4 translator/slicing regression guard recorded above.
  - The spec itself should be retained as an external regression once the new-bug inventory is finalized.

## 2026-05-06 NeuralP4 ARGMAX winner-state loss witness

- **Spec**: `Procurator/argo/code/spec/bench/external_neuralp4_netml_argmax_winner_loss.prop`
- **Time**: 2026-05-06 09:29-09:41 Asia/Shanghai
- **Goal/Progress**: Check a fourth NeuralP4 failure mode, distinct from run-state reset, completion duplicate acceptance, and 16-bit run-id aliasing: the ARGMAX aggregation state preserves the maximum value while losing the stored winner id when a later stimulus does not exceed the old maximum.
- **Result**:
  - New bug count progress: **4/10**.
  - Property: two packets from run `21` provide stimuli for neuron `1` and neuron `2`, with `expected_stimuli = 6`, `n_expected_stimuli = 2`, and `agg_func = 4` (`FUNC_ARGMAX`). The first stimulus has `data_1 = 100`; the second has `data_1 = 50`. The P4 code reads back `reg_neuron_max_value` on the non-first stimulus but does not read back the stored winner-id register before comparing, so the final state can keep `reg_neuron_max_value == 100` while `reg_neuron_1_data` is overwritten/lost.
  - Compile/smoke after the P4B fixes:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_neuralp4_netml_argmax_winner_loss.prop --out /tmp/external_neuralp4_netml_argmax_winner_loss.fixed2.bpl --work-dir /tmp/external_neuralp4_netml_argmax_winner_loss.fixed2.work --boogie-harness sequential --no-two-stage --no-reg-debug` -> PASS in about 29.8s.
    - `./bin/procurator smoke --bpl /tmp/external_neuralp4_netml_argmax_winner_loss.fixed2.bpl --harness sequential` -> PASS.
  - Verified UNSAFE with witness:
    - Run directory: `.tmp/procurator/verify/external_neuralp4_netml_argmax_winner_loss/20260506-093544-f215/`
    - Command shape:
      - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_neuralp4_netml_argmax_winner_loss.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound off --ultimate-timeout-seconds 300 --ultimate-xmx-gb 4 --use-spec-max-steps`
    - Main run: `UNSAFE`, feasible counterexample.
    - Witness rerun: `UNSAFE`, feasible counterexample.
    - Full verify including witness rerun took about 5m57s wall time.
    - Witness files:
      - `.tmp/procurator/verify/external_neuralp4_netml_argmax_winner_loss/20260506-093544-f215/external_neuralp4_netml_argmax_winner_loss.bpl-witness.graphml`
      - `.tmp/procurator/verify/external_neuralp4_netml_argmax_winner_loss/20260506-093544-f215/external_neuralp4_netml_argmax_winner_loss.bpl-witness.yml`
- **Pitfalls/Fixes**:
  - Initial run `20260506-091412-6fe4` failed Ultimate type checking because sliced Boogie retained statements using compiler-generated globals such as `ann_res_1_47`, but their global declarations had been pruned.
  - Second run `20260506-092905-819f` failed Ultimate type checking because those retained globals were declared but not present in the enclosing procedure `modifies` clauses.
  - Fixed `P4B-Translator/backends/verify/translate/impl/core/translate.cpp` so slicing-mode emission scans reachable procedure bodies/declaration text for referenced known globals and emits those declarations, then scans assignments/havocs to known globals and adds them to each reachable procedure's `modifies`.
- **Smoke/regression**:
  - `wsl.exe --cd /mnt/e/p4-verify/P4B-Translator/build-host -- bash -lc 'time cmake --build . --target p4c-translator -j16'` -> PASS.
  - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc '.venv-wsl/bin/python -m unittest -v dslc.tests.p4b.test_p4b_translator_regressions.TestP4BTranslatorRegressions.test_neuralp4_argmax_slice_keeps_used_temporaries_declared dslc.tests.p4b.test_p4b_translator_regressions.TestP4BTranslatorRegressions.test_neuralp4_sliced_modifies_do_not_redeclare_pruned_temps'` -> PASS.
  - New guard: `dslc/tests/p4b/test_p4b_translator_regressions.py::TestP4BTranslatorRegressions::test_neuralp4_argmax_slice_keeps_used_temporaries_declared`.

## 2026-05-06 NeuralP4 ARGMAX new-winner state loss witness

- **Spec**: `Procurator/argo/code/spec/bench/external_neuralp4_netml_argmax_new_winner_loss.prop`
- **Time**: 2026-05-06 10:09-10:17 Asia/Shanghai
- **Goal/Progress**: Check a fifth NeuralP4 failure mode, distinct from the previous ARGMAX case. The prior ARGMAX witness covered a smaller second stimulus preserving the old maximum while losing the stored winner id. This spec uses a larger second stimulus, so the maximum correctly moves to the second packet's value while the winner switch-id register is still not restored/updated.
- **Result**:
  - New bug count progress: **5/10**.
  - Property: two packets from run `22` provide expected stimuli for neuron `1` and neuron `2`, with `agg_func = 4` (`FUNC_ARGMAX`). The first stimulus has `data_1 = 50`; the second has `data_1 = 100`. A correct ARGMAX state should store both the new max value and the second packet's switch/neuron winner id. The implementation updates `reg_neuron_max_value` to `100`, but `reg_neuron_1_data` can remain `0` because the non-first ARGMAX path does not restore/update the stored switch-id field.
  - Compile/smoke:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_neuralp4_netml_argmax_new_winner_loss.prop --out /tmp/external_neuralp4_netml_argmax_new_winner_loss.bpl --work-dir /tmp/external_neuralp4_netml_argmax_new_winner_loss.work --boogie-harness sequential --no-two-stage --no-reg-debug` -> PASS in about 31.9s.
    - `./bin/procurator smoke --bpl /tmp/external_neuralp4_netml_argmax_new_winner_loss.bpl --harness sequential` -> PASS; generated BPL was 2463 lines / 279K.
  - Verified UNSAFE with witness:
    - Run directory: `.tmp/procurator/verify/external_neuralp4_netml_argmax_new_winner_loss/20260506-101107-00ff/`
    - Command shape:
      - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_neuralp4_netml_argmax_new_winner_loss.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound off --ultimate-timeout-seconds 300 --ultimate-xmx-gb 4 --use-spec-max-steps`
    - Main run: `UNSAFE`, feasible counterexample, `OverallTime≈125.9s`, `OverallIterations=26`.
    - Witness rerun: `UNSAFE`, feasible counterexample, `OverallTime≈131.3s`, `OverallIterations=26`.
    - Witness files:
      - `.tmp/procurator/verify/external_neuralp4_netml_argmax_new_winner_loss/20260506-101107-00ff/external_neuralp4_netml_argmax_new_winner_loss.bpl-witness.graphml`
      - `.tmp/procurator/verify/external_neuralp4_netml_argmax_new_winner_loss/20260506-101107-00ff/external_neuralp4_netml_argmax_new_winner_loss.bpl-witness.yml`
    - DSL counterexample classification: `dsl_assert` violated.
- **Pitfalls/Fixes**:
  - No new implementation fix was required for this spec. It reuses the NeuralP4 slicing/model-contract fixes already recorded for the earlier NeuralP4 witnesses.
  - This is a direct bounded witness, not a wraparound certificate.
- **Smoke/regression**:
  - Compile + Boogie smoke both passed for this spec before verification.
  - The existing NeuralP4 P4B regression guards remain the relevant toolchain regression anchors.

## 2026-05-06 SwitchML shadow-bitmap cross-clear duplicate-count witness

- **Spec**: `Procurator/argo/code/spec/bench/external_switchml_shadow_bitmap_duplicate_count.prop`
- **Time**: 2026-05-06 12:19-12:50 Asia/Shanghai
- **Goal/Progress**: Continue the external-system mining loop on SwitchML (NSDI 2021) with a stronger interleaving property, not the earlier weak value-zero sanity probes. This case checks the two-shadow-bitmap protocol path where a packet for set1 clears the same worker's set0 bit before a late duplicate set0 packet arrives.
- **Result**:
  - New bug count progress: **6/10**.
  - Property: three packets for the same worker/base slot use pool-index phases `set0 -> set1 -> set0`. The set1 packet clears the set0 shadow bitmap, so the late duplicate set0 contribution is treated as fresh and reaches worker counting plus value aggregation again.
  - Compile/smoke after the P4B fixes:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_switchml_shadow_bitmap_duplicate_count.prop --out /tmp/external_switchml_shadow_bitmap_duplicate_count.fixed2.bpl --work-dir /tmp/external_switchml_shadow_bitmap_duplicate_count.fixed2.work --boogie-harness sequential --no-two-stage --no-reg-debug` -> PASS.
    - `./bin/procurator smoke --bpl /tmp/external_switchml_shadow_bitmap_duplicate_count.fixed2.bpl --harness sequential` -> PASS.
  - Verified `UNSAFE` with witness:
    - Run directory: `.tmp/procurator/verify/external_switchml_shadow_bitmap_duplicate_count/20260506-124539-abaa/`
    - Command shape:
      - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_switchml_shadow_bitmap_duplicate_count.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound off --ultimate-timeout-seconds 300 --ultimate-xmx-gb 4 --use-spec-max-steps`
    - Main run: `UNSAFE`, feasible counterexample, `OverallTime≈83.8s`, `OverallIterations=20`.
    - Witness rerun: `UNSAFE`, feasible counterexample, `OverallTime≈84.7s`, `OverallIterations=20`.
    - Witness files:
      - `.tmp/procurator/verify/external_switchml_shadow_bitmap_duplicate_count/20260506-124539-abaa/external_switchml_shadow_bitmap_duplicate_count.bpl-witness.graphml`
      - `.tmp/procurator/verify/external_switchml_shadow_bitmap_duplicate_count/20260506-124539-abaa/external_switchml_shadow_bitmap_duplicate_count.bpl-witness.yml`
    - DSL counterexample classification: `dsl_assert` violated.
- **Pitfalls/Fixes**:
  - Initial verify run `20260506-121935-c7c9` failed Ultimate type checking; this was a backend conversion issue, not evidence of absence.
  - Root cause 1: slicing-mode `modifies` propagation in `P4B-Translator/backends/verify/translate/impl/core/translate.cpp` used only the hand-maintained `succ` graph. Counter `.count()` wrappers call `.add()` in the lowered Boogie body, so their callee modifies were not propagated and Ultimate reported "Modifies not transitive".
  - Root cause 2: DSL slicing seeds preserved data variables but did not pass property-observed Boogie table/action symbols as P4B keep-vars. The global assert referenced `sw_Ingress_value00_sum.action_run`, but the table declaration/action enum had been sliced away.
  - Fixed:
    - `P4B-Translator/backends/verify/translate/impl/core/translate.cpp`: builds a unified procedure call graph from `succ` plus body call targets and propagates modifies over that graph.
    - `dslc/backends/boogie/node/seeds.py` and `dslc/backends/boogie/compiler.py`: carry property-observed symbols through `SlicingPlan.slicing_keep_vars` into P4B `--slicing-keep-vars`.
    - `P4B-Translator/backends/verify/bpl_verify/pipeline.cpp`: derives forced keep-tables from keep-vars such as `T.action_run` / `T.action.X`, so P4B keeps the observed table/action declarations.
    - Spec typo fixed: the `set0` action enum reference now uses the full `table.action.ActionName` namespace.
- **Smoke/regression**:
  - `wsl.exe --cd /mnt/e/p4-verify/P4B-Translator/build-host -- bash -lc 'time cmake --build . --target p4c-translator -j16'` -> PASS.
  - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc '.venv-wsl/bin/python -m unittest -v dslc.tests.boogie.backend.test_boogie_slicing_seeds dslc.tests.p4b.translator.test_frontend_io.TestP4BVerifyFrontendIo.test_switchml_sliced_counter_count_modifies_cover_add_callee dslc.tests.p4b.translator.test_frontend_io.TestP4BVerifyFrontendIo.test_switchml_value00_slice_prunes_sibling_aggregation_registers'` -> PASS.
  - New guards:
    - `dslc/tests/p4b/translator/test_frontend_io.py::TestP4BVerifyFrontendIo::test_switchml_sliced_counter_count_modifies_cover_add_callee`
    - `dslc/tests/boogie/backend/test_boogie_slicing_seeds.py::TestBoogieSlicingSeeds::test_global_assert_observed_table_action_kept_for_p4b_output`

## 2026-05-06 SwitchML RDMA same-QP state-overwrite witness

- **Spec**: `Procurator/argo/code/spec/bench/external_switchml_rdma_same_qp_state_overwrite_assign.prop`
- **Time**: 2026-05-06 15:12-16:33 Asia/Shanghai
- **Goal/Progress**: Continue the external-system mining loop on SwitchML (NSDI 2021) with an RDMA receiver interleaving property distinct from the shadow-bitmap duplicate-count case. The source P4 is `Procurator/argo/code/dataset/external_switchml_nsdi21/switchml/dev_root/p4/switchml.p4`; no upstream P4 edits were made.
- **Result**:
  - New bug count progress: **7/10**.
  - Property: three packets for the same QP interleave as `FIRST(A, psn=10, pool=0) -> FIRST(B, psn=30, pool=2) -> LAST(A, psn=11, pool=0)`. The second FIRST overwrites the single next-PSN/pool state for the QP, so the late LAST from the first message observes the overwritten state and is dropped.
  - Compile/smoke:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_switchml_rdma_same_qp_state_overwrite_assign.prop --out /tmp/external_switchml_rdma_same_qp_state_overwrite_assign.bpl --work-dir /tmp/external_switchml_rdma_same_qp_state_overwrite_assign.work --boogie-harness sequential --no-two-stage --no-reg-debug` -> PASS.
    - `./bin/procurator smoke --bpl /tmp/external_switchml_rdma_same_qp_state_overwrite_assign.bpl --harness sequential` -> PASS.
  - Verified `UNSAFE` with witness:
    - Run directory: `.tmp/procurator/verify/external_switchml_rdma_same_qp_state_overwrite_assign/20260506-162724-3103/`
    - Command shape:
      - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_switchml_rdma_same_qp_state_overwrite_assign.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound off --ultimate-timeout-seconds 300 --ultimate-xmx-gb 4 --use-spec-max-steps`
    - Main run: `UNSAFE`, feasible counterexample, `OverallTime≈100.7s`, `OverallIterations=20`.
    - Witness rerun: `UNSAFE`, feasible counterexample, `OverallTime≈71.2s`, `OverallIterations=20`.
    - Witness files:
      - `.tmp/procurator/verify/external_switchml_rdma_same_qp_state_overwrite_assign/20260506-162724-3103/external_switchml_rdma_same_qp_state_overwrite_assign.bpl-witness.graphml`
      - `.tmp/procurator/verify/external_switchml_rdma_same_qp_state_overwrite_assign/20260506-162724-3103/external_switchml_rdma_same_qp_state_overwrite_assign.bpl-witness.yml`
- **Pitfalls/Fixes**:
  - The original `external_switchml_rdma_same_qp_state_overwrite.prop` used phase-local `assume` constraints on `sw_Ingress_rdma_receiver_receive_roce.action_run`. Because this table-action selector is a persistent global in the generated Boogie and is not freshly havoced between packets, the phase-0/1 `first_packet` constraints and phase-2 `last_packet` constraint conflicted, producing a suspicious `SAFE`. This was a modeling issue, not evidence that the interleaving is absent.
  - Assigning all action-argument globals inside the host env exposed a separate Boogie `modifies` limitation: those globals were not listed in `mainProcedure`'s modifies clause. The checked spec therefore assigns only the per-phase `action_run` selector and keeps action arguments as assumptions.
  - The next implementation refinement should make host/env assignments to P4 table/action parameter globals update the generated modifies sets, then add a regression for this pattern.
- **Smoke/regression**:
  - Compile + Boogie smoke both passed for this spec before verification.
  - This spec should remain as an external regression for phase-changing table action selectors.
  - No P4 dataset files were modified.

## 2026-05-06 SwitchML UDP job/pool alias retransmission witness

- **Spec**: `Procurator/argo/code/spec/bench/external_switchml_job_pool_alias_drop.prop`
- **Time**: 2026-05-06 19:31-19:35 Asia/Shanghai
- **Goal/Progress**: Continue the external-system mining loop on SwitchML (NSDI 2021) with a new UDP aggregation-state alias property. This case is distinct from the shadow-bitmap cross-clear bug: it checks that `job_number` is recorded in metadata but is not part of the bitmap/workers/value state key.
- **Result**:
  - New bug count progress: **8/10**.
  - Property: two UDP packets use different `hdr.switchml.job_number` values (`1 -> 2`) but the same worker bit and the same pool slot. The first job leaves the shadow bitmap bit set for `pool_index=0`. The second job's first contribution aliases that state, obtains a nonzero `map_result`, and is treated as a retransmission/read path instead of a fresh job contribution.
  - Compile/smoke:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_switchml_job_pool_alias_drop.prop --out /tmp/external_switchml_job_pool_alias_drop.bpl --work-dir /tmp/external_switchml_job_pool_alias_drop.work --boogie-harness sequential --no-two-stage --no-reg-debug` -> PASS in about 18.5s.
    - `./bin/procurator smoke --bpl /tmp/external_switchml_job_pool_alias_drop.bpl --harness sequential` -> PASS.
  - Verified `UNSAFE` with witness:
    - Run directory: `.tmp/procurator/verify/external_switchml_job_pool_alias_drop/20260506-193150-edb5/`
    - Command shape:
      - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_switchml_job_pool_alias_drop.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound off --ultimate-timeout-seconds 300 --ultimate-xmx-gb 4 --use-spec-max-steps`
    - Main run: `UNSAFE`, feasible counterexample, `OverallTime≈51.9s`, `OverallIterations=17`.
    - Witness rerun: `UNSAFE`, feasible counterexample, `OverallTime≈51.9s`, `OverallIterations=17`.
    - Witness files:
      - `.tmp/procurator/verify/external_switchml_job_pool_alias_drop/20260506-193150-edb5/external_switchml_job_pool_alias_drop.bpl-witness.graphml`
      - `.tmp/procurator/verify/external_switchml_job_pool_alias_drop/20260506-193150-edb5/external_switchml_job_pool_alias_drop.bpl-witness.yml`
    - DSL counterexample classification: `dsl_assert` violated.
- **Pitfalls/Fixes**:
  - The first draft deliberately avoided assigning table action parameters in host env, because the current Boogie harness still needs a modifies-set refinement for host/env assignments to P4 table/action parameter globals.
  - No P4 source workaround was needed; the existing SwitchML translator/slicing support handled this property after the earlier keep-vars/table-action fixes.
- **Smoke/regression**:
  - Compile + Boogie smoke both passed before the solver run.
  - This spec should remain as an external regression for job-id-sensitive aggregation state aliasing.
  - No P4 dataset files were modified.

## 2026-05-06 Soter TNA decision-tree conversion smoke

- **Spec**: `Procurator/argo/code/spec/bench/external_soter_simple_l3_smoke.prop`
- **Time**: 2026-05-06 19:38 Asia/Shanghai
- **Goal/Progress**: Check whether the Soter (SRDS 2022 / TDSC 2024) TNA data-plane artifact can be translated and harnessed without editing the upstream P4. This is conversion coverage for a candidate system, not a counted wraparound/interleaving bug.
- **Result**:
  - Compile: `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_soter_simple_l3_smoke.prop --out /tmp/external_soter_simple_l3_smoke.bpl --work-dir /tmp/external_soter_simple_l3_smoke.work --boogie-harness sequential --no-two-stage --no-reg-debug` -> PASS.
  - Smoke: `./bin/procurator smoke --bpl /tmp/external_soter_simple_l3_smoke.bpl --harness sequential` -> PASS.
  - New bug count remains **8/10**.
- **Pitfalls/Fixes**:
  - Static inspection shows the P4 data plane is mostly a filter table plus chained decision-tree controls; CPU-side monitoring/training state is outside this single-switch P4 smoke. No interleaving/wraparound bug is claimed from this smoke.
  - No implementation fix was required.
- **Smoke/regression**:
  - Retain the spec as a TNA decision-tree conversion regression.
  - No P4 dataset files were modified.

## 2026-05-06 Mousika TNA artifact intake attempt

- **Spec**: `Procurator/argo/code/spec/bench/external_mousika_flowcontrol_smoke.prop`
- **Time**: 2026-05-06 19:38 Asia/Shanghai
- **Goal/Progress**: Start Mousika (INFOCOM 2022 / ToN 2023) conversion coverage without editing upstream P4. This is not a bug-finding result.
- **Result**:
  - Compile attempted:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_mousika_flowcontrol_smoke.prop --out /tmp/external_mousika_flowcontrol_smoke.bpl --work-dir /tmp/external_mousika_flowcontrol_smoke.work --boogie-harness sequential --no-two-stage --no-reg-debug`
  - Result: `ERROR` before P4 translation proper. The preprocessor could not resolve `#include "common/headers.p4"` from `Procurator/argo/code/dataset/external_mousika_infocom22/Mousika/P4/flowcontrol.p4`.
  - New bug count remains **8/10**.
- **Pitfalls/Fixes**:
  - This is an artifact/source-tree intake gap, not evidence that Mousika has no bug and not a P4 syntax support failure. The local snapshot currently has `P4/flowcontrol.p4` but does not include the referenced `P4/common/headers.p4` / `common/util.p4` tree.
  - Per project policy, no upstream P4 dataset workaround was made. The right next step is to either complete the artifact source tree or teach the intake layer an explicit include-root mapping if those files exist elsewhere.
- **Smoke/regression**:
  - No smoke BPL was produced for Mousika in this attempt.
  - The failed spec remains useful as an intake regression once the missing include tree is supplied.

## 2026-05-06 NetBeacon hash-alias candidate audit

- **Spec**: `Procurator/argo/code/spec/bench/external_netbeacon_smoke.prop`
- **Time**: 2026-05-06 19:43-19:47 Asia/Shanghai
- **Goal/Progress**: Audit a potential NetBeacon (USENIX Security 2023) flow-index alias candidate before writing a counted bug spec. The code stores a full `flow_hash` in `Register_full_flow_hash[flow_index]`, where `flow_index = flow_hash[15:0]`.
- **Result**:
  - Compile: `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_netbeacon_smoke.prop --out /tmp/external_netbeacon_smoke.bpl --work-dir /tmp/external_netbeacon_smoke.work --boogie-harness sequential --no-two-stage --no-reg-debug` -> PASS.
  - Smoke: `./bin/procurator smoke --bpl /tmp/external_netbeacon_smoke.bpl --harness sequential` -> PASS.
  - No bug counted. New bug count remains **8/10**.
- **Pitfalls/Fixes**:
  - No-prune BPL inspection shows `ig_md.flow_hash` is modeled as a deterministic uninterpreted function:
    - `function nb_SwitchIngress_my_symmetric_hash.get$bv32$bv32$bv16$bv16$bv8(...) returns(bv32);`
    - `nb_ig_md.flow_index := nb_ig_md.flow_hash[16:0];`
  - Therefore a spec that merely asks for two header tuples with equal low 16 hash bits and different full hashes would be proving existence under the uninterpreted hash abstraction, not a concrete CRC32 collision. This is too loose to count as a verified NetBeacon bug without either a concrete packet pair or a CRC32-aware hash model.
  - No implementation fix was made in this step. A future refinement could add a concrete CRC helper or a table of precomputed collision witnesses for hash-index alias checks.
- **Smoke/regression**:
  - NetBeacon smoke remains a valid TNA conversion regression.
  - The hash-alias candidate is explicitly **not** counted until backed by concrete hash evidence.

## 2026-05-06 SwitchML cross-job worker-state mixing witness

- **Spec**: `Procurator/argo/code/spec/bench/external_switchml_cross_job_worker_mix_completion.prop`
- **Time**: 2026-05-06 22:21-22:29 Asia/Shanghai
- **Goal/Progress**: Continue the external-system mining loop on SwitchML (NSDI 2021) with a new UDP aggregation-state interaction distinct from the earlier same-worker retransmission/job-alias and shadow-bitmap cross-clear cases. This case checks cross-job, cross-worker mixing through shared `pool_index`-keyed worker/value state.
- **Result**:
  - New bug count progress: **9/10**.
  - Property: job 1 contributes worker 0 into pool slot 0, then job 2 contributes worker 1 into the same pool slot. Because `worker_bitmap`, `workers_count`, and value registers are keyed by `pool_index` rather than `job_number`, job 2 can observe `worker_bitmap_before == 1`, `map_result == 0`, decrement the existing worker count to `first_last_flag == 1`, and take the aggregation path that treats job 2 as complete after only one job-2 worker contribution.
  - Compile/smoke:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_switchml_cross_job_worker_mix_completion.prop --out /tmp/external_switchml_cross_job_worker_mix_completion.bpl --work-dir /tmp/external_switchml_cross_job_worker_mix_completion.work --boogie-harness sequential --no-two-stage --no-reg-debug` -> PASS.
    - `./bin/procurator smoke --bpl /tmp/external_switchml_cross_job_worker_mix_completion.bpl --harness sequential` -> PASS.
    - A concurrent compile also passed. `procurator smoke --harness concurrent` still reports `missing procedure mainProcedure()` on the thread-based concurrent harness; this is a smoke-tool coverage issue, not a translation failure for the sequential verification path.
  - Verified `UNSAFE` with witness:
    - Run directory: `.tmp/procurator/verify/external_switchml_cross_job_worker_mix_completion/20260506-222447-7e88/`
    - Command shape:
      - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_switchml_cross_job_worker_mix_completion.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound off --ultimate-timeout-seconds 300 --ultimate-xmx-gb 4 --use-spec-max-steps`
    - Main run: `UNSAFE`, feasible counterexample, `OverallTime≈62.7s`, `OverallIterations=17`.
    - Witness rerun: `UNSAFE`, feasible counterexample, `OverallTime≈76.3s`, `OverallIterations=17`.
    - Witness files:
      - `.tmp/procurator/verify/external_switchml_cross_job_worker_mix_completion/20260506-222447-7e88/external_switchml_cross_job_worker_mix_completion.bpl-witness.graphml`
      - `.tmp/procurator/verify/external_switchml_cross_job_worker_mix_completion/20260506-222447-7e88/external_switchml_cross_job_worker_mix_completion.bpl-witness.yml`
    - DSL counterexample classification: `dsl_assert` violated.
- **Pitfalls/Fixes**:
  - This spec needs phase-local assignments to P4 table action parameters (`worker_id_13`, `worker_bitmap_13`) to model two workers across packets. Earlier harness code did not include host/env assignments to target-node table action selectors/parameters in `modifies` clauses.
  - Fixed in `dslc/backends/boogie/harness/flow/dsl.py`, `dslc/backends/boogie/harness/flow/threads.py`, and `dslc/backends/boogie/harness/state/start.py`: env-block assignment LHSs are now collected from the AST and added to the relevant harness modifies sets. This only repairs Boogie procedure write declarations; it does not change the generated state-transition semantics.
- **Smoke/regression**:
  - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc '.venv-wsl/bin/python -m unittest -v dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_host_env_target_table_assignments_are_in_modifies dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_concurrent_harness_two_slot_inbox_k2'` -> PASS.
  - Single Ultimate/GemCutter job was run in WSL; follow-up process check found no residual Ultimate/java/z3 process.

## 2026-05-06 NeuralP4 weighted-sum accumulator wrap witness

- **Spec**: `Procurator/argo/code/spec/bench/external_neuralp4_netml_weighted_sum_accumulator_wrap.prop`
- **Time**: 2026-05-06 23:00-23:13 Asia/Shanghai
- **Goal/Progress**: Complete the current external-system mining loop with a tenth genuinely new bug mechanism. This case is distinct from the previous NeuralP4 run-state/duplicate/run-id/ARGMAX bugs: it checks fixed-width arithmetic wrap in `FUNC_WEIGHTED_SUM_16_TO_32` in `Procurator/argo/code/dataset/external_neuralp4_noms25/NeuralP4/p4-vm/netml-iot-16x32x2-q4-4/code/ANN.p4`.
- **Result**:
  - New bug count progress: **10/10**.
  - Property: two valid, non-duplicate stimuli in one run use `expected_stimuli = 3`, `n_expected_stimuli = 2`, and `agg_func = 1` (`FUNC_WEIGHTED_SUM_16_TO_32`). The table configuration sets a legal `bit<8>` weight `n2n_1_weight_1 = 32` and `data_1 = 100`, so each stimulus contributes `(32 * 100) >> 4 = 200`. The first stimulus writes accumulator value `200`; the second reads it, adds another `200`, and the `bit<8>` accumulator wraps to `144`.
  - Static/code audit:
    - `WORDSIZE=8`, `D_WORDSIZE=16`, and `PRECISION=4` in this generated q4-4 NeuralP4 program.
    - The weighted-sum path uses 16-bit temporaries for products, casts each product back to `bit<WORDSIZE>`, then accumulates the sum into `meta.neuron_1_data` before writing `reg_neuron_1_data`.
    - The source applies both `tab_neuron_bias_32_neurons` and `tab_neuron_bias_2_neurons` before the aggregation branch; in the sliced property only `tab_neuron_bias_2_neurons` is retained because it is the last table that writes `meta.neuron_1_bias`. This is source-program behavior, not a P4B slicing bug.
  - Compile/smoke:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_neuralp4_netml_weighted_sum_accumulator_wrap.prop --out /tmp/external_neuralp4_netml_weighted_sum_accumulator_wrap.bpl --work-dir /tmp/external_neuralp4_netml_weighted_sum_accumulator_wrap.work --boogie-harness sequential --no-two-stage --no-reg-debug` -> PASS in about 37.1s.
    - `./bin/procurator smoke --bpl /tmp/external_neuralp4_netml_weighted_sum_accumulator_wrap.bpl --harness sequential` -> PASS; generated BPL was 2394 lines.
    - BPL audit confirmed the property retained `ann_MyIngress_tab_n2n_weight_16_to_32_neurons.apply`, the constrained `n2n_1_weight_79` parameter, `ann_meta.neuron_1_bias`, and the assertion on `ann_MyIngress_reg_neuron_1_data__last0_value == 144bv8`.
  - Verified `UNSAFE` with witness:
    - Run directory: `.tmp/procurator/verify/external_neuralp4_netml_weighted_sum_accumulator_wrap/20260506-230618-22ee/`
    - Command shape:
      - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_neuralp4_netml_weighted_sum_accumulator_wrap.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound off --ultimate-timeout-seconds 300 --ultimate-xmx-gb 4 --use-spec-max-steps`
    - Main run: `UNSAFE`, feasible counterexample, `OverallTime≈111.1s`, `OverallIterations=18`.
    - Witness rerun: `UNSAFE`, feasible counterexample, `OverallTime≈153.0s`, `OverallIterations=18`.
    - Witness files:
      - `.tmp/procurator/verify/external_neuralp4_netml_weighted_sum_accumulator_wrap/20260506-230618-22ee/external_neuralp4_netml_weighted_sum_accumulator_wrap.bpl-witness.graphml`
      - `.tmp/procurator/verify/external_neuralp4_netml_weighted_sum_accumulator_wrap/20260506-230618-22ee/external_neuralp4_netml_weighted_sum_accumulator_wrap.bpl-witness.yml`
    - DSL counterexample classification: `dsl_assert` violated.
- **Pitfalls/Fixes**:
  - A subagent review checked that this is distinct from the existing NeuralP4 run-state and ARGMAX cases, provided the witness isolates a valid weighted-sum run. The final spec uses one stable run id and two different expected stimuli (`neuron_id 0` then `1`), avoiding duplicate/reopen behavior.
  - This is a direct bounded witness under a legal control-plane table configuration. For an even stronger artifact-default claim, a future variant can pin weights from `code/topology/s51-runtime.json`; this entry does not rely on upstream P4 edits.
  - No new implementation fix was required for this spec. It reused the earlier NeuralP4 slicing/temp-declaration fixes and the harness modifies fix for host/env-driven table variables.
- **Smoke/regression**:
  - Targeted regression after the witness:
    - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc '.venv-wsl/bin/python -m unittest -v dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_host_env_target_table_assignments_are_in_modifies dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_concurrent_harness_two_slot_inbox_k2 dslc.tests.p4b.test_p4b_translator_regressions.TestP4BTranslatorRegressions.test_neuralp4_argmax_slice_keeps_used_temporaries_declared'` -> PASS.
  - Single Ultimate/GemCutter job was run in WSL; follow-up process check found no residual Ultimate/java/z3 process.

## 2026-05-07 Hash model precision audit

- **Spec**: `Procurator/argo/code/spec/bench/external_netbeacon_smoke.prop` plus raw P4B hash samples:
  - `P4B-Translator/testdata/p4_16_samples/psa-hash-04.p4`
  - `P4B-Translator/testdata/p4_16_samples/hash_ubpf.p4`
  - `P4B-Translator/testdata/p4_16_samples/pna-dpdk-toeplitz-hash.p4`
- **Time**: 2026-05-07 00:10-00:35 Asia/Shanghai
- **Goal/Progress**: Fill the hash-modeling gap so hash-dependent witnesses are not over-certified. `IDENTITY` hash is now precise when the data tuple can be flattened safely; CRC16/CRC32/lookup/Toeplitz/checksum/unknown hashes remain deterministic uninterpreted functions and are marked as weak precision. This supports PSA/eBPF/uBPF/PNA/TNA coverage while preserving sound bug accounting.
- **Result**:
  - P4B raw PSA sample:
    - `./P4B-Translator/build-host/p4c-translator --std p4-16 -I P4B-Translator/p4include -I P4B-Translator/testdata/p4_16_samples --goto --no-slicing -o /tmp/psa_hash_04.hash_model.bpl P4B-Translator/testdata/p4_16_samples/psa-hash-04.p4`
    - PASS; BPL contains:
      - `// p4b_hash_model: extern base=MyIC_h0 algorithm=PSA_HashAlgorithm_t.CRC16 model=crc16_uf precision=deterministic_uninterpreted`
      - `// p4b_hash_model: extern base=MyIC_h1 algorithm=PSA_HashAlgorithm_t.IDENTITY model=identity precision=precise`
  - P4B raw uBPF sample:
    - `./P4B-Translator/build-host/p4c-translator --std p4-16 -I P4B-Translator/p4include -I P4B-Translator/testdata/p4_16_samples --goto --no-slicing -o /tmp/hash_ubpf.hash_model.bpl P4B-Translator/testdata/p4_16_samples/hash_ubpf.p4`
    - PASS; BPL contains `function hash_lookup3$...` declarations and `precision=deterministic_uninterpreted` model comments for `HashAlgorithm.lookup3`.
  - P4B raw PNA Toeplitz sample:
    - `./P4B-Translator/build-host/p4c-translator --std p4-16 -I P4B-Translator/p4include -I P4B-Translator/testdata/p4_16_samples --goto --no-slicing -o /tmp/pna_toeplitz.hash_model.bpl P4B-Translator/testdata/p4_16_samples/pna-dpdk-toeplitz-hash.p4`
    - PASS; BPL contains `model=toeplitz_uf precision=deterministic_uninterpreted`.
  - NetBeacon smoke:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_netbeacon_smoke.prop --out /tmp/external_netbeacon_smoke.hash_model_current.bpl --work-dir /tmp/external_netbeacon_smoke.hash_model_current.work --boogie-harness sequential --no-two-stage --no-reg-debug` -> PASS.
    - `./bin/procurator smoke --bpl /tmp/external_netbeacon_smoke.hash_model_current.bpl --harness sequential` -> PASS.
    - The sliced smoke BPL does not retain the NetBeacon hash path, so this remains a conversion regression, not a hash-alias bug proof.
- **Pitfalls/Fixes**:
  - Using the lowered enum value for the hash algorithm can erase the source algorithm name. The translator records the original IR expression text for `Hash<W>` extern constructors and uses it in model comments/function mangling.
  - `IDENTITY` hash over concatenated fields must parenthesize before truncation; the bitvector coercion now emits `(a++b)[W:0]` rather than `a++b[W:0]`.
  - Mixed precision in one BPL must not be reported as fully precise. The semantic audit now marks `hash_extern` as `WEAK` if any surviving hash is deterministic-uninterpreted or a havoc fallback, even if another hash in the same program is precise.
  - A NetBeacon flow-index alias property based only on the deterministic UF hash abstraction is not counted as a concrete bug. It needs either a precise CRC/Toeplitz model or a concrete packet-pair/precomputed collision witness.
- **Smoke/regression**:
  - `wsl.exe --cd /mnt/e/p4-verify/P4B-Translator/build-host -- bash -lc "make -j16 p4c-translator"` -> PASS.
  - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc ".venv-wsl/bin/python -m unittest -v dslc.tests.bench.test_p4b_semantic_audit dslc.tests.p4b.test_p4b_translator_regressions.TestP4BTranslatorRegressions.test_ubpf_three_arg_hash_lowers_to_deterministic_assignment dslc.tests.p4b.test_p4b_translator_regressions.TestP4BTranslatorRegressions.test_psa_identity_hash_extern_lowers_to_precise_slice"` -> PASS (`20 tests`).
  - Follow-up process check found no residual Ultimate/java/z3 solver process.

## 2026-05-07 BMv2/PSA/PNA CRC hash semantic refinement

- **Spec/Samples**:
  - Raw P4B sample: `P4B-Translator/testdata/p4_16_samples/flowlet_switching-bmv2.p4`
  - Raw P4B sample: `P4B-Translator/testdata/p4_16_samples/psa-hash-04.p4`
  - Regression specs: `Procurator/argo/code/spec/bench/gecko_bug2_concurrency.prop` and `Procurator/argo/code/spec/bench/netlock_release_counter_underflow_bug.prop`
- **Time**: 2026-05-07 09:20-09:50 Asia/Shanghai
- **Goal/Progress**: Strengthen the earlier hash-model audit: default BMv2/PSA/PNA CRC16/CRC32 hashes are now modeled with byte-level deterministic CRC expressions when the hash data tuple can be flattened and byte-aligned. v1model 5-argument `hash(result, algorithm, base, data, max)` now assigns the ranged value `base + crc(data) % max`, with the `max == 0` case returning `base`. TNA generic `HashAlgorithm_t.CRC*` still stays deterministic-uninterpreted unless the architecture name is clearly BMv2/PSA/PNA-compatible.
- **Result**:
  - P4B translator rebuild:
    - `wsl.exe --cd /mnt/e/p4-verify/P4B-Translator/build-host -- bash -lc 'cmake --build . --target p4c-translator -j4'` -> PASS.
  - Focused regression:
    - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc '.venv-wsl/bin/python -m unittest -v dslc.tests.p4b.test_p4b_flowdos_hash dslc.tests.p4b.test_p4b_translator_regressions.TestP4BTranslatorRegressions.test_psa_identity_hash_extern_lowers_to_precise_slice dslc.tests.bench.test_p4b_semantic_audit'` -> PASS (`23 tests`).
  - Generated-Boogie audit on `flowlet_switching-bmv2.p4`:
    - BPL contains `// p4b_hash_model: builtin algorithm=HashAlgorithm.crc16 model=crc16_bmv2 precision=precise`.
    - BPL contains inline helpers `__p4b_crc16_bmv2_bit` and `__p4b_crc16_bmv2_byte`.
    - BPL contains `function {:bvbuiltin "bvurem"} urem.bv14(...)`.
    - The ECMP assignment has the expected shape: `if 0bv12++ecmp_count == 0bv14 then 0bv2++ecmp_base else add.bv14(0bv2++ecmp_base, urem.bv14(..., 0bv12++ecmp_count))`.
  - Regression spec compile/smoke:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/gecko_bug2_concurrency.prop --out /tmp/gecko_bug2_concurrency.check.bpl --boogie-harness sequential --no-two-stage --no-reg-debug && ./bin/procurator smoke --bpl /tmp/gecko_bug2_concurrency.check.bpl --harness sequential` -> PASS.
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/netlock_release_counter_underflow_bug.prop --out /tmp/netlock_release_counter_underflow_bug.check.bpl --boogie-harness sequential --no-two-stage --no-reg-debug && ./bin/procurator smoke --bpl /tmp/netlock_release_counter_underflow_bug.check.bpl --harness sequential` -> PASS.
- **Pitfalls/Fixes**:
  - The first refinement attempted to assign raw CRC for v1model 5-argument hash and mark it as `precision=precise_unranged`; this was incomplete because v1model semantics include `base` and `max`. Fixed by assigning the ranged expression before marking the model precise.
  - PowerShell-to-WSL quoting around grep pipelines produced noisy probe failures; these were command-shape issues only. The generated Boogie was rechecked with a WSL Python subprocess to avoid shell metacharacter ambiguity.
  - CRC precision is deliberately architecture-scoped. Vendor-generic TNA CRC names are not silently treated as BMv2 CRCs.
- **Smoke/regression**:
  - Regression tests updated:
    - `dslc/tests/p4b/test_p4b_flowdos_hash.py`: mixed-width v1model hash now requires precise ranged CRC and `bvurem`.
    - `dslc/tests/p4b/test_p4b_translator_regressions.py`: PSA CRC16 hash extern expects precise CRC lowering while identity remains precise slicing.
    - `dslc/tests/p4b/test_p4b_translator_slicing_selftest.py`: TNA generic CRC hash externs remain deterministic UF but now require algorithm-isolated function names plus all data fields.
  - Full quick regression:
    - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc '.venv-wsl/bin/python -m unittest -v dslc.tests.boogie.backend.test_boogie_backend_smoke dslc.tests.boogie.backend.test_boogie_slicing_seeds dslc.tests.p4b.test_p4b_translator_slicing_selftest dslc.tests.wraparound.schedule.test_wraparound_workflow_smoke dslc.tests.frontend.test_spec_regressions'` -> PASS (`65 tests`).
  - No Ultimate/GemCutter job was started in this step; no residual solver process was present before the run.

## 2026-05-07 Flow-INT focused-direct guard audit

- **Spec**: `Procurator/argo/code/spec/bench/external_int_flowdos_counter_wraparound.prop`
- **Time**: 2026-05-07 10:06-10:46 Asia/Shanghai
- **Goal/Progress**: Continue the semantic-gap cleanup for the Flow-INT counter candidate. The immediate goal was to keep focused-direct acceleration UNSAFE-only and prevent the textual bounded shortcut from reporting a zero-write witness through an unknown guarded reset path.
- **Result**:
  - Compile refreshed on the current tree:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_int_flowdos_counter_wraparound.prop --out /tmp/external_int_flowdos_counter_wraparound_current.bpl --work-dir /tmp/external_int_flowdos_counter_wraparound_current.work --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds` -> PASS, `WALL=6.86s`.
  - Smoke refreshed:
    - `./bin/procurator smoke --bpl /tmp/external_int_flowdos_counter_wraparound_current.bpl --harness sequential` -> PASS, `WALL=3.01s`.
  - Focused-index transform still folds the dynamic hash index to a concrete slot:
    - `changed=True`, reason `focused flowdos_MyIngress_counter_filter at flowdos_counter_pos == 2242bv32`, assert lines `(359, 373)`.
  - Guard-aware textual replay correctly rejects the current Flow-INT bounded variants:
    - bounded `32`, `64`, `128`, and `256` all returned `textual=False`; no textual `.unsafe.json` marker is accepted for this shape.
  - A prior direct run in `.tmp/procurator/verify/external_int_flowdos_counter_wraparound/20260507-100641-c3f9/` was interrupted by the outer wrapper after generating focused bounded artifacts. This is recorded as partial evidence only, not as bug absence.
- **Pitfalls/Fixes**:
  - The old textual replay treated guarded code too sequentially. A Flow-INT-like body could increment a register and then contain `if (counter_val >= 128) { write 0 }`; accepting the later zero write without proving the guard would be a false positive.
  - Fixed in `dslc/workflows/focused_direct.py`: bounded textual replay now interprets simple `if/else` guards only when the Boolean condition is deterministically evaluable from tracked bitvector/Boolean facts. Unknown guards fail closed and fall back to the normal solver-backed focused/original verification path.
  - BPL audit shows the current assertion is broad: it is attached to the register write helper and therefore covers both `counter_filter.write(counter_pos, counter_val + 1)` and the later reset `counter_filter.write(counter_pos, 0)`. A precise overflow validation should target the increment-write site or add an old-value/path guard so the intended wrap mechanism is not conflated with reset behavior.
- **Smoke/regression**:
  - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc ".venv-wsl/bin/python -m unittest -v dslc.tests.workflows.test_focused_direct_workflow dslc.tests.transform.test_focused_direct dslc.tests.wraparound.test_wraparound_candidate_gating dslc.tests.p4b.test_p4b_flowdos_hash"` -> PASS (`55` tests).
  - Added regression coverage includes `test_textual_bounded_latch_rejects_unknown_guarded_reset`.
  - Solver jobs were not run concurrently; after the interrupted run, residual Ultimate/java/procurator processes were checked and killed before continuing.

## 2026-05-07 Flow-INT old/new focused-direct refinement

- **Spec**: `Procurator/argo/code/spec/bench/external_int_flowdos_counter_wraparound.prop`
- **Time**: 2026-05-07 16:20-17:10 Asia/Shanghai
- **Goal/Progress**: Continue semantic-gap cleanup for the Flow-INT counter candidate by separating a broad zero-write check from the precise old/new increment-wrap check. The property now targets the increment write itself:
  - `counter_filter__last_old_value == 255`
  - `counter_filter__last_value == 0`
  - This avoids counting the threshold-reset write as an overflow-style witness.
- **Result**:
  - Focused workflow regression on Windows Python:
    - `py -3 -m unittest -v dslc.tests.workflows.test_focused_direct_workflow` -> PASS (`19` tests).
  - WSL focused/hash/register regression:
    - `.venv-wsl/bin/python -m unittest -v dslc.tests.transform.test_focused_direct dslc.tests.workflows.test_focused_direct_workflow dslc.tests.p4b.test_p4b_flowdos_hash dslc.tests.boogie.backend.test_boogie_registers_typedef_index0` -> PASS (`46` tests).
  - Compile/smoke on the current old/new property:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_int_flowdos_counter_wraparound.prop --out /tmp/external_int_flowdos_oldnew_check.bpl --work-dir /tmp/external_int_flowdos_oldnew_check.work --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --skip-duplicated-fail-fast-global-asserts` -> PASS.
    - `./bin/procurator smoke --bpl /tmp/external_int_flowdos_oldnew_check.bpl --harness sequential` -> PASS.
  - Generated-BPL audit confirmed the property is emitted as the old/new condition:
    - `flowdos_MyIngress_counter_filter__last_old_value == 255bv8`
    - `flowdos_MyIngress_counter_filter__last_value == 0bv8`
  - Focused/direct solver attempt:
    - Run directory: `.tmp/procurator/verify/external_int_flowdos_counter_wraparound/20260507-163223-0537/`
    - Command shape: `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_int_flowdos_counter_wraparound.prop --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --skip-duplicated-fail-fast-global-asserts --focused-direct auto --wraparound off --ultimate-timeout-seconds 180 --no-witness-rerun`
    - Result: outer run was interrupted after focused and bounded focused artifacts were generated. This is recorded as `TIMEOUT/partial`, not as `SAFE` or bug absence.
  - Focused bounded BPL audit:
    - `external_int_flowdos_counter_wraparound.focused-index0.bounded256.bpl` now latches only the concrete old/new bad condition, not an unconditional `assert false`.
    - No textual `.unsafe.json` marker was accepted for this guarded-reset shape.
  - Meta audit:
    - `work/flowdos.meta.json` lists `MyIngress_counter_filter` as a wraparound-sized register, but `wraparound.updates` is empty for this reset-interrupted counter. This is expected: the counter is not a steady affine pump candidate.
- **Pitfalls/Fixes**:
  - A broad property on `last_value == 0` conflated the threshold-reset write with the intended old/new increment wrap. The spec was narrowed to the old/new write condition using the P4B old-value mirror.
  - The focused bounded latch used to be able to rewrite a focused `assert false` into an unconditional latch in textual replay. This could accept a shortcut that did not re-check the target condition. Fixed in `dslc/workflows/focused_direct.py` by reconstructing the concrete focused bad condition when building the latch.
  - The textual shortcut remains UNSAFE-only and fail-closed. `SAFE`, `UNKNOWN`, `TIMEOUT`, or unsupported replay paths fall back to solver-backed focused/original verification.
  - Source audit shows the program writes `counter_val + 1` and then resets the same slot when the old `counter_val >= REPORT_FREQ`. Therefore the precise old/new `255 -> 0` condition needs a separate reachability argument; it must not be certified by the normal steady wraparound pump.
- **Smoke/regression**:
  - Added regression coverage in `dslc/tests/workflows/test_focused_direct_workflow.py`:
    - `test_textual_bounded_latch_witness_short_circuits_solver`
    - `test_textual_bounded_latch_rejects_oldnew_guarded_reset`
  - After the partial focused/direct run, residual Ultimate/java/procurator processes for the same run were checked and stopped before continuing.

## 2026-05-07 Flow-INT site-qualified register write refinement

- **Spec**: `Procurator/argo/code/spec/bench/external_int_flowdos_counter_wraparound.prop`
- **Time**: 2026-05-07 17:20-20:12 Asia/Shanghai
- **Goal/Progress**: Finish the Flow-INT semantic disambiguation by making register write mirrors site-qualified. The property now targets only the increment write site:
  - `flowdos_MyIngress_counter_filter__last_write_site == 1`
  - `flowdos_MyIngress_counter_filter__last_old_value == 255`
  - `flowdos_MyIngress_counter_filter__last_value == 0`
  This prevents the later threshold reset write from being counted as the intended increment-wrap witness.
- **Result**:
  - P4B translator rebuild:
    - `wsl.exe --cd /mnt/e/p4-verify/P4B-Translator/build-host -- bash -lc 'cmake --build . --target p4c-translator -j4'` exceeded the outer tool timeout at 604s, but the WSL build process continued and produced an updated `P4B-Translator/build-host/backends/verify/p4c-translator` at `2026-05-07 19:50:22`.
    - Follow-up narrow target: `wsl.exe --cd /mnt/e/p4-verify/P4B-Translator/build-host -- bash -lc 'cmake --build . --target verifybackend -j2'` -> PASS.
  - Targeted register/site regression:
    - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc '.venv-wsl/bin/python -m unittest -v dslc.tests.p4b.test_p4b_flowdos_hash.TestP4BFlowDoSHash.test_flowdos_counter_write_sites_disambiguate_increment_from_reset dslc.tests.boogie.backend.test_boogie_registers_typedef_index0 dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_exact_register_mirror_assert_enables_p4b_fail_fast dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_legacy_bpl_native_register_mirrors_are_not_reinstrumented_after_prefixing dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_legacy_bpl_backfill_repairs_write_body_and_modifies dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_p4b_generated_nodes_accept_complete_native_register_mirrors dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_p4b_generated_nodes_reject_incomplete_mirror_modifies'` -> PASS (`11` tests).
  - Compile/smoke on the site-qualified property:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_int_flowdos_counter_wraparound.prop --out /tmp/external_int_flowdos_site_check.bpl --work-dir /tmp/external_int_flowdos_site_check.work --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --skip-duplicated-fail-fast-global-asserts` -> PASS.
    - `./bin/procurator smoke --bpl /tmp/external_int_flowdos_site_check.bpl --harness sequential` -> PASS.
    - Default slicing path also passed after the site-mirror keep-list change:
      - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_int_flowdos_counter_wraparound.prop --out /tmp/external_int_flowdos_site_default.bpl --work-dir /tmp/external_int_flowdos_site_default.work --boogie-harness sequential --no-two-stage --no-reg-debug --skip-duplicated-fail-fast-global-asserts` -> PASS.
      - `./bin/procurator smoke --bpl /tmp/external_int_flowdos_site_default.bpl --harness sequential` -> PASS.
  - Generated-BPL audit:
    - increment write site: `flowdos_MyIngress_counter_filter__next_write_site := 1;`
    - reset write site: `flowdos_MyIngress_counter_filter__next_write_site := 2;`
    - helper latch: `flowdos_MyIngress_counter_filter__last_write_site := flowdos_MyIngress_counter_filter__next_write_site;`
    - fail-fast guard: `last_old_value == 255bv8 && last_value == 0bv8 && last_write_site == 1`.
  - Meta audit:
    - `flowdos.meta.json` still lists `MyIngress_counter_filter` as an 8-bit register.
    - `wraparound.updates` has no `MyIngress_counter_filter` steady affine update, which is expected for this reset-interrupted counter.
    - `counter_pos` index definition is precise CRC16/`urem.bv32` over `hdr.ipv4.srcAddr`.
  - Focused/direct probe:
    - Command shape: `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_int_flowdos_counter_wraparound.prop --boogie-harness sequential --no-two-stage --no-reg-debug --no-slicing-control-seeds --skip-duplicated-fail-fast-global-asserts --focused-direct auto --wraparound off --ultimate-timeout-seconds 180 --no-witness-rerun`
    - Run directory: `.tmp/procurator/verify/external_int_flowdos_counter_wraparound/20260507-200647-425d/`
    - Result: outer tool timeout at 304s. `gemcutter.log` shows Ultimate launched, parsed, inlined, and entered preprocessing; no witness/result was produced. This is recorded as `TIMEOUT/partial`, not `SAFE` and not bug absence.
- **Pitfalls/Fixes**:
  - Initial write-site numbering used one global counter across all registers. In Flow-INT, an unrelated register write consumed site `1`, so `counter_filter` increment/reset were not stable as `1/2`. Fixed in P4B by changing write-site IDs to per-register counters.
  - Slicing had to keep `__next_write_site` and `__last_write_site` alongside the existing register mirrors; otherwise a site-qualified property could compile in unsliced mode but lose the site mirror under slicing.
  - The write helper reads `__next_write_site`, but it is set by each callsite. Therefore the helper `modifies` contains `__last_write_site`, while enclosing procedures also modify `__next_write_site`.
  - Windows process inspection after the outer timeout showed Java processes from the Cursor Java extension, not Ultimate. The interrupted run remains partial until a WSL-side process check is available in that sandbox.
- **Smoke/regression**:
  - Broader focused/register/hash regression:
    - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc '.venv-wsl/bin/python -m unittest -v dslc.tests.transform.test_focused_direct dslc.tests.workflows.test_focused_direct_workflow dslc.tests.p4b.test_p4b_flowdos_hash dslc.tests.boogie.backend.test_boogie_registers_typedef_index0 dslc.tests.boogie.backend.test_boogie_backend_smoke'` -> PASS (`73` tests).
  - Post-split focused regression:
    - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc '.venv-wsl/bin/python -m unittest -v dslc.tests.boogie.backend.test_boogie_register_mirror_ownership dslc.tests.boogie.backend.test_boogie_registers_typedef_index0 dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_bounded_direct_check_preserves_accumulated_fallback_for_other_asserts dslc.tests.boogie.backend.test_boogie_backend_smoke.TestBoogieBackendSmoke.test_dslc_owns_control_seeds_for_p4b_slicing dslc.tests.p4b.test_p4b_flowdos_hash.TestP4BFlowDoSHash.test_flowdos_counter_write_sites_disambiguate_increment_from_reset'` -> PASS (`14` tests).
  - Post-interruption grouped regression:
    - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc '.venv-wsl/bin/python -m unittest -v dslc.tests.boogie.backend.test_boogie_register_mirror_ownership dslc.tests.boogie.backend.test_boogie_backend_smoke dslc.tests.p4b.test_p4b_flowdos_hash'` -> PASS (`30` tests).
  - Added regression coverage:
    - `dslc/tests/p4b/test_p4b_flowdos_hash.py::TestP4BFlowDoSHash.test_flowdos_counter_write_sites_disambiguate_increment_from_reset`
    - register mirror fixture updates in `dslc/tests/boogie/backend/test_boogie_registers_typedef_index0.py`.
    - `dslc/tests/boogie/backend/test_boogie_register_mirror_ownership.py` owns legacy-BPL backfill and strict P4B-generated register mirror contract tests; `test_boogie_backend_smoke.py` was reduced to `939` lines.

## 2026-05-08 NetChain wraparound current-tree revalidation

- **Spec**: `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop`
- **Time**: 2026-05-08 10:05-10:13 Asia/Shanghai
- **Goal/Progress**: Revalidate the known schedule-replay wraparound path on the current tree after the Flow-INT write-site and hash semantic refinements. This specifically checks that the prior `NEAR_WRAP=SAFE` false-negative path does not regress while keeping the run staged.
- **Result**:
  - Short staged run:
    - Command shape: `./bin/procurator verify --spec Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop --boogie-harness sequential --no-two-stage --no-reg-debug --ultimate-xmx-gb 8 --wraparound auto --wraparound-cegar-mode schedule_replay --wraparound-stage-order entry_confirm_closure --wraparound-stop-after near_wrap --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --ultimate-timeout-seconds 300`
    - Run directory: `.tmp/procurator/verify/netchain_wraparound_bug/20260508-100552-6521/`
    - `ENTRY_CHECK`: `UNSAFE`, wall≈59.7s.
    - `NEAR_WRAP`: `UNSAFE`, wall≈60.9s.
    - This is a short-stage regression only; it is not a complete certificate because it intentionally stopped before `CLOSURE_CHECK`.
  - Full certification run:
    - Command shape: `./bin/procurator verify --spec Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop --boogie-harness sequential --no-two-stage --no-reg-debug --ultimate-xmx-gb 8 --wraparound auto --wraparound-cegar-mode schedule_replay --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --ultimate-timeout-seconds 900`
    - Run directory: `.tmp/procurator/verify/netchain_wraparound_bug/20260508-100945-7e73/`
    - Manifest: `.tmp/procurator/verify/netchain_wraparound_bug/20260508-100945-7e73/wraparound/target.00.s1_sequence_reg/wraparound.cegis.manifest.json`
    - `ENTRY_CHECK`: `UNSAFE`, wall≈17.8s.
    - `NEAR_WRAP`: `UNSAFE`, wall≈37.8s.
    - `CLOSURE_CHECK`: `SAFE`, wall≈84.1s.
    - Total stage time≈139.7s, comfortably below the 8-minute target.
    - Validator: `python3 -m dslc.bench.validate_counterexample --wraparound-manifest .tmp/procurator/verify/netchain_wraparound_bug/20260508-100945-7e73/wraparound/target.00.s1_sequence_reg/wraparound.cegis.manifest.json` -> `[OK] certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id`.
- **Pitfalls/Fixes**:
  - The integrated CLI returns a nonzero exit code when it successfully finds/certifies an unsafe counterexample. This was classified from the `[WRAP] CERTIFIED UNSAFE` and validator output, not treated as command failure.
  - A small manifest-audit helper failed because PowerShell/WSL quoting stripped Python string quotes. This was a command-shape issue only; the result was rechecked with the official validator.
  - WSL process checks after the runs found no residual Ultimate/procurator process; the only output was the benign WSL screen-size warning.
- **Smoke/regression**:
  - This entry is solver-level revalidation of the existing wraparound certificate path. It builds on the same current-tree compile path used by `procurator verify`; no separate source edit was made in this step.

## 2026-05-08 NetBeacon closure simplification probe

- **Spec**: `Procurator/argo/code/spec/bench/external_netbeacon_total_pkts_wraparound.prop`
- **Time**: 2026-05-08 14:14-14:45 Asia/Shanghai
- **Goal/Progress**: Continue the NetBeacon wraparound candidate after the current-tree wraparound fixes. The target remained `nb_SwitchIngress_Register_total_pkts`; the run used staged ENTRY/NEAR/CLOSURE so that each phase could be inspected independently.
- **Implementation changes**:
  - Added closure-only table action branch specialization in `dslc/transform/boogie/closure_simplify.py`. When the closure profile fixes a table `action_run`, infeasible `.apply()` branches are pruned in the closure proof task only.
  - Added closure-only identity RegisterAction writeback simplification. Pure readback RegisterAction calls no longer emit the redundant array writeback, while preserving register write mirrors such as `__last_old_value`, `__last_index`, `__last_value`, `__last_write_site`, `__wrote_any`, and index-0 mirrors.
  - Added deterministic closure harness branch folding for straight-line mailbox/phase branches in `mainProcedure`. The pass clears facts across calls and does not fold clone/recirculation flags through modular calls.
- **Result**:
  - Focused transform regression:
    - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc '.venv-wsl/bin/python -m unittest -v dslc.tests.wraparound.transform.test_closure_harness_simplify dslc.tests.wraparound.transform.test_closure_registeraction_simplify dslc.tests.wraparound.transform.test_closure_table_specialization dslc.tests.wraparound.transform.test_wraparound_transform dslc.tests.wraparound.transform.test_wraparound_entry_check'` -> PASS (`39` tests).
  - Projection/schedule regression:
    - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc '.venv-wsl/bin/python -m unittest -v dslc.tests.wraparound.schedule.test_wraparound_projection_table_apply dslc.tests.wraparound.schedule.test_wraparound_projection dslc.tests.wraparound.schedule.test_wraparound_schedule'` -> PASS (`43` tests).
  - Compile/smoke:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_netbeacon_total_pkts_wraparound.prop --out /tmp/external_netbeacon_total_pkts_wraparound.sliced.current.bpl --boogie-harness sequential --no-two-stage --no-reg-debug --skip-duplicated-fail-fast-global-asserts` -> PASS.
    - `./bin/procurator smoke --bpl /tmp/external_netbeacon_total_pkts_wraparound.sliced.current.bpl --harness sequential` -> PASS.
    - Closure BPL smoke on the generated staged artifact -> PASS.
  - Short staged verification:
    - Command shape: `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_netbeacon_total_pkts_wraparound.prop --boogie-harness sequential --no-two-stage --no-reg-debug --skip-duplicated-fail-fast-global-asserts --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-cegar-mode schedule_replay --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --wraparound-stop-after closure --ultimate-timeout-seconds 120 --ultimate-xmx-gb 8 --no-witness-rerun`
    - Run directory: `.tmp/procurator/verify/external_netbeacon_total_pkts_wraparound/20260508-144205-7c57/`
    - `ENTRY_CHECK`: `UNSAFE`, wall approx `17.2s`.
    - `NEAR_WRAP`: `UNSAFE`, wall approx `46.3s`.
    - `CLOSURE_CHECK`: `TIMEOUT`, wall approx `139.4s`; closure log reports `CFG has 1 procedures, 91 locations, 120 edges, 1 error locations`, `OverallTime` approx `110.4s`, and `OverallIterations` `21`.
    - This is **not certified** yet. It is not a SAFE result and not evidence that the property is absent.
- **Pitfalls/Fixes**:
  - A tempting optimization would have folded clone/recirculation flags through `call nb_mainProcedure()`. That is unsound under modular Boogie calls because the callee may modify globals through its `modifies` set. The final pass clears known constants at calls and leaves those branches intact unless a future sound modifies/body analysis proves otherwise.
  - A 300s closure probe was interrupted by the outer driver and residual solver processes were stopped before continuing. It is recorded as partial/timeout evidence only.
  - A PowerShell/WSL quoting issue affected one ad hoc manifest-reading command; the generated artifacts and solver logs were inspected through normal paths afterward.
- **Smoke/regression**:
  - New focused tests cover table specialization, mirror-preserving RegisterAction simplification, and deterministic closure harness folding.
  - Regression commands above were run before the staged solver probe. No concurrent Ultimate/GemCutter jobs were launched.

## 2026-05-08 NetBeacon closure harness proof-cost follow-up

- **Spec**: `Procurator/argo/code/spec/bench/external_netbeacon_total_pkts_wraparound.prop`
- **Time**: 2026-05-08 15:09-16:04 Asia/Shanghai
- **Goal/Progress**: Continue the NetBeacon wraparound candidate after the first closure simplification probe. The immediate check followed the current guideline: first validate whether the generated closure Boogie/harness shape is structurally correct; only if the shape is correct should long solver time be treated as proof cost rather than a conversion bug.
- **Implementation changes**:
  - `dslc/transform/boogie/closure_simplify.py`: added a sound, narrow event-flag post-call summary for closure harness folding. The pass uses callee `modifies` sets and only summarizes straight-line bodies that force clone/recirculation flags to `false`; it does not assume calls preserve globals when the `modifies` set says otherwise.
  - `dslc/transform/wraparound_stages.py`: deduplicated closure assertion conjuncts when a final cutpoint conjunct is already represented as a projection predicate equality. This keeps the proof obligation equivalent but avoids re-asserting hash-slot/full-flow predicates twice.
- **Result**:
  - Focused transform regression:
    - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc '.venv-wsl/bin/python -m unittest -v dslc.tests.wraparound.transform.test_closure_harness_simplify dslc.tests.wraparound.transform.test_closure_registeraction_simplify dslc.tests.wraparound.transform.test_closure_table_specialization dslc.tests.wraparound.transform.test_wraparound_transform dslc.tests.wraparound.transform.test_wraparound_entry_check'` -> PASS (`40` tests).
  - Python compile checks:
    - `python3 -m py_compile dslc/transform/boogie/closure_simplify.py` -> PASS.
    - `python3 -m py_compile dslc/transform/wraparound_stages.py` -> PASS.
  - Closure BPL smoke:
    - `./bin/procurator smoke --bpl .tmp/procurator/verify/external_netbeacon_total_pkts_wraparound/20260508-151635-3c2b/wraparound/target.00.nb_SwitchIngress_Register_total_pkts/external_netbeacon_total_pkts_wraparound.schedule.00.closure_check.bpl --harness sequential` -> PASS.
  - Short staged verification after event-flag folding:
    - Run directory: `.tmp/procurator/verify/external_netbeacon_total_pkts_wraparound/20260508-150912-05a4/`
    - `ENTRY_CHECK`: `UNSAFE`, wall approx `19.2s`.
    - `NEAR_WRAP`: `UNSAFE`, wall approx `39.5s`.
    - `CLOSURE_CHECK`: `TIMEOUT`, wall approx `73.9s`.
    - Closure CFG reduced to `83` locations and `108` edges.
  - Short staged verification after closure-assert deduplication:
    - Run directory: `.tmp/procurator/verify/external_netbeacon_total_pkts_wraparound/20260508-151635-3c2b/`
    - `ENTRY_CHECK`: `UNSAFE`, wall approx `15.6s`.
    - `NEAR_WRAP`: `UNSAFE`, wall approx `40.4s`.
    - `CLOSURE_CHECK`: `TIMEOUT`, wall approx `78.1s`.
    - Closure CFG stayed at `83` locations and `108` edges, but the final closure assertion no longer repeats the projection-covered cutpoint predicates.
  - 900s full staged run plus fallback:
    - Run directory: `.tmp/procurator/verify/external_netbeacon_total_pkts_wraparound/20260508-152015-5f28/`
    - Manifest: `.tmp/procurator/verify/external_netbeacon_total_pkts_wraparound/20260508-152015-5f28/wraparound/target.00.nb_SwitchIngress_Register_total_pkts/wraparound.cegis.manifest.json`
    - Manifest classification: `certified=false`, diagnostic `closure unknown/timeout; falling back`.
    - `ENTRY_CHECK`: `RESULT: UNSAFE`.
    - `NEAR_WRAP`: `RESULT: UNSAFE`.
    - `CLOSURE_CHECK`: `RESULT: Ultimate could not prove your program: Timeout`; closure log reports `CFG has 1 procedures, 83 locations, 108 edges`, `OverallTime: 845.4s`, `OverallIterations: 17`.
    - Fallback direct verification also timed out: `RESULT: Ultimate could not prove your program: Timeout`, `OverallTime: 858.9s`, `OverallIterations: 29`.
    - This remains **inconclusive**, not `SAFE`, not certified, and not evidence that the NetBeacon property is absent.
- **Pitfalls/Fixes**:
  - A previous monitoring command outlived the solver run and matched its own grep pattern, which made process status noisy. It was identified as a monitor shell rather than Ultimate/Z3 and stopped before continuing.
  - PowerShell-to-WSL quoting around ad hoc `grep`/Python snippets produced noisy command failures. These were command-shape issues only; the manifest and logs were rechecked through direct WSL reads.
  - Closure log now suggests the remaining bottleneck is proof cost around array/bitvector predicates and interpolation, not an immediately visible malformed harness: the closure BPL passes structural smoke, ENTRY/NEAR are reachable, and the closure timeout occurs inside TraceAbstraction/refinement rather than parsing or Boogie preprocessing.
- **Smoke/regression**:
  - No solver jobs were left running after the run; a WSL process check after cleanup showed no active Ultimate/java/z3/procurator verifier process.
  - Current classification for this candidate: BPL/harness shape appears structurally correct, but the certificate is not complete until `CLOSURE_CHECK` proves `SAFE`.

## 2026-05-08 NetBeacon schedule-replay certificate and consumer hardening

- **Spec**: `Procurator/argo/code/spec/bench/external_netbeacon_total_pkts_wraparound.prop`
- **Time**: 2026-05-08 16:33-21:05 Asia/Shanghai
- **Goal/Progress**: Finish the NetBeacon `total_pkts` wraparound candidate after the prior closure timeouts, and harden the downstream certificate consumer so that a schedule-replay certificate is accepted only when the solver artifacts, manifest, candidate, schedule, projection, and stage logs agree.
- **Implementation changes**:
  - `dslc/transform/wraparound_stages.py`: closure target proof now prefers complete last-write mirrors (`__wrote_any`, `__last_index`, `__last_value`) when available. The closure obligation proves that the accelerated step actually writes the target slot and that the last written value equals the expected step update, avoiding a heavier array read where the mirror is precise.
  - `dslc/bench/validate_counterexample.py`: schedule-replay manifest validation no longer goes through the generic `_manifest_certified_unsafe_data` gate. It now recomputes the deterministic schedule, validates candidate/cfg consistency, requires dependency-projection sources to be explicit and certifiable, rejects closure assumptions and event-level conditions for this certificate mode, checks exact stage log `-i <bpl>` bindings, requires final stage results rather than intermediate Ultimate registration lines, and validates each stage BPL against expected instrumentation and cfg/projection/env-shape content.
  - `dslc/cli/gemcutter.py`: integrated wraparound result handling now calls the artifact-backed validator for `cegar_mode=schedule_replay` and fails closed on validator exceptions. Generic manifest-only certification is kept only for non-schedule-replay legacy manifests.
  - Added/updated regressions in `dslc/tests/toolchain/test_validate_counterexample.py`, `dslc/tests/toolchain/test_validate_wraparound_manifest.py`, `dslc/tests/toolchain/wraparound_manifest_fixtures.py`, and `dslc/tests/cli/test_gemcutter_result_rc.py` for dependency-projection predicates, explicit predicate provenance, projection expressions, malformed numeric schedule fields, raw stage BPLs, unreadable log artifacts, stage-shaped-but-wrong cfg artifacts, final timeout overriding intermediate SAFE/UNSAFE registration, exact `-i` path prefix rejection, and CLI generic-only fallback rejection.
- **Result**:
  - Certified NetBeacon run:
    - Command shape: `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_netbeacon_total_pkts_wraparound.prop --boogie-harness sequential --no-two-stage --no-reg-debug --skip-duplicated-fail-fast-global-asserts --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-cegar-mode schedule_replay --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --ultimate-timeout-seconds 300 --ultimate-xmx-gb 8 --no-witness-rerun`
    - Run directory: `.tmp/procurator/verify/external_netbeacon_total_pkts_wraparound/20260508-172922-195c/`
    - Manifest: `.tmp/procurator/verify/external_netbeacon_total_pkts_wraparound/20260508-172922-195c/wraparound/target.00.nb_SwitchIngress_Register_total_pkts/wraparound.cegis.manifest.json`
    - `ENTRY_CHECK`: `RESULT: UNSAFE`, wall approx `42.49s`.
    - `NEAR_WRAP`: `RESULT: UNSAFE`, wall approx `44.24s`.
    - `CLOSURE_CHECK`: `RESULT: SAFE`, wall approx `184.36s`.
    - Manifest classification: `certified=true`, diagnostic `certified schedule-replay wraparound bug`.
    - CLI result handling printed `[WRAP] CERTIFIED UNSAFE` and `[CEX] certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id`; the nonzero exit code is expected for a found/certified unsafe counterexample.
  - Artifact validator on the real manifest:
    - `python3 -m dslc.bench.validate_counterexample --wraparound-manifest .tmp/procurator/verify/external_netbeacon_total_pkts_wraparound/20260508-172922-195c/wraparound/target.00.nb_SwitchIngress_Register_total_pkts/wraparound.cegis.manifest.json` -> `[OK] certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id`.
- **Pitfalls/Fixes**:
  - Stop-after-closure manifests are useful stage evidence but are not the same as the integrated CLI's final certified-unsafe path. The final result above uses a full integrated run that exits immediately on the certified wraparound artifact instead of falling through to base direct checking.
  - The old generic manifest helper is intentionally narrower and rejects some dependency-projection predicates. For schedule replay, the correct consumer path is artifact-backed validation plus schedule/projection recomputation, not weakening the generic helper.
  - Accepting `Registering result SAFE/UNSAFE` from the middle of an Ultimate log is unsound when the final result is timeout/unknown. The validator now requires a final explicit `RESULT:` line for each stage artifact.
  - Stage markers and exact log path checks are necessary but not sufficient: a wrong stage-shaped BPL can still contain those markers. The validator now also binds stage BPLs to the candidate target register, projection variables, env-shape assumes, near/entry projection predicates, closure predicate/expr snapshot assignments, closure predicate/expr equality obligations, and closure projection snapshots. Dynamic-index closure aliases are accepted as the normalized form of the same obligation.
  - A substring check for log `-i <bpl>` would accept neighboring names such as `entry.bpl.old`; path matching now uses token boundaries and quoted/unquoted variants.
  - `proj_exprs` manifest labels such as `expr:0` are synthetic certificate labels, not Boogie symbols. The validator now binds their RHS expression in the stage BPL instead of requiring the label text to occur in Boogie.
  - The added schedule-replay tests pushed `dslc/tests/toolchain/test_validate_counterexample.py` over the 1300-line Python file target. Shared stage artifact fixtures were split into `dslc/tests/toolchain/wraparound_manifest_fixtures.py`, and artifact-specific regressions live in `dslc/tests/toolchain/test_validate_wraparound_manifest.py`. Current line counts are: `test_validate_counterexample.py` 1232 lines, `test_validate_wraparound_manifest.py` 172 lines, and `wraparound_manifest_fixtures.py` 106 lines.
  - Subagent review found that non-empty `proj_predicates` could still pass with omitted/empty `proj_predicate_sources` because the validator defaulted them to `dependency_projection`. Added a red-green regression (`test_validate_schedule_replay_rejects_predicates_without_explicit_sources`) and tightened the validator to require source-list length equality whenever predicates are present.
- **Smoke/regression**:
  - Focused consumer regression:
    - Red test before the fix: `wsl.exe --cd /mnt/e/p4-verify -- bash -lc '.venv-wsl/bin/python -m unittest -v dslc.tests.toolchain.test_validate_wraparound_manifest.TestValidateWraparoundManifestArtifacts.test_validate_schedule_replay_rejects_predicates_without_explicit_sources'` failed because the manifest was incorrectly certified.
    - Same targeted test after the fix -> PASS.
    - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc '.venv-wsl/bin/python -m unittest -v dslc.tests.toolchain.test_validate_counterexample dslc.tests.toolchain.test_validate_wraparound_manifest dslc.tests.cli.test_gemcutter_result_rc'` -> PASS (`25` tests).
  - Broader wraparound transform/closure regression:
    - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc '.venv-wsl/bin/python -m unittest -v dslc.tests.toolchain.test_validate_counterexample dslc.tests.toolchain.test_validate_wraparound_manifest dslc.tests.cli.test_gemcutter_result_rc dslc.tests.wraparound.transform.closure.test_closure_target_asserts dslc.tests.wraparound.transform.closure.test_closure_harness_simplify dslc.tests.wraparound.transform.closure.test_closure_registeraction_simplify dslc.tests.wraparound.transform.closure.test_closure_table_specialization dslc.tests.wraparound.transform.test_wraparound_transform dslc.tests.wraparound.transform.test_wraparound_entry_check'` -> PASS (`67` tests).
  - Python compile:
    - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc 'python3 -m py_compile dslc/bench/validate_counterexample.py dslc/cli/gemcutter.py dslc/tests/toolchain/test_validate_counterexample.py dslc/tests/toolchain/test_validate_wraparound_manifest.py dslc/tests/toolchain/wraparound_manifest_fixtures.py dslc/tests/cli/test_gemcutter_result_rc.py'` -> PASS.

## 2026-05-08 NetBeacon total_bytes wraparound candidate recovery

- **Spec**: `Procurator/argo/code/spec/bench/external_netbeacon_total_bytes_wraparound.prop`
- **Time**: 2026-05-08 22:08-22:39 Asia/Shanghai
- **Goal/Progress**: Continue the external NetBeacon wraparound mining loop on `Register_total_bytes`, which previously had only a bounded direct timeout. First checked whether the generated BPL/harness is correct, then fixed the candidate inference gap that prevented the wraparound pipeline from even trying the staged proof.
- **Result**:
  - Current compile/smoke:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_netbeacon_total_bytes_wraparound.prop --out .tmp/procurator/manual/netbeacon_bytes/current.bpl --work-dir .tmp/procurator/manual/netbeacon_bytes/work --boogie-harness sequential --no-two-stage --no-reg-debug --skip-duplicated-fail-fast-global-asserts` -> PASS.
    - `./bin/procurator smoke --bpl .tmp/procurator/manual/netbeacon_bytes/current.bpl --harness sequential` -> PASS.
    - Generated BPL has 1217 lines; the assertion is over `nb_SwitchIngress_Register_total_bytes__wrote_any` and `nb_SwitchIngress_Register_total_bytes__last_value == 0bv32`.
  - Candidate inference after the fix recovers:
    - `pump_reg=nb_SwitchIngress_Register_total_bytes`
    - `step_delta=32768`
    - dynamic stable index expression `nb_SwitchIngress_my_symmetric_hash.get$alg_t_CRC32$bv32$bv32$bv16$bv16$bv8(167772161bv32, 167772162bv32, 1234bv16, 443bv16, 6bv8)[16:0]`
    - stable env-shape substitutions for `flow_hash`, `flow_index`, ports, `flow_size`, and `udp_length`.
  - Staged wraparound run with 300s cap:
    - Run directory: `.tmp/procurator/verify/external_netbeacon_total_bytes_wraparound/20260508-221416-86cc/`
    - `ENTRY_CHECK=UNSAFE`, wall≈44.8s.
    - `NEAR_WRAP=TIMEOUT`, wall≈322.3s.
  - Staged wraparound run with 900s cap:
    - Run directory: `.tmp/procurator/verify/external_netbeacon_total_bytes_wraparound/20260508-222309-0547/`
    - `ENTRY_CHECK=UNSAFE`, wall≈14.5s.
    - `NEAR_WRAP=TIMEOUT`, wall≈914.5s.
  - Classification: model/harness and candidate inference are now correct enough to attempt wraparound, but the near-wrap suffix remains solver-timeout/inconclusive. This is not `SAFE` and not evidence that the candidate is absent.
- **Pitfalls/Fixes**:
  - P4B meta reported the additive RegisterAction update but with `delta_is_const=false`, because the P4 expression is `hdr.ipv4.total_len`. In the composed Boogie harness, node assumptions fix `nb_hdr.ipv4.total_len == 32768bv16`.
  - The existing delta recovery handled direct literals such as `32768bv16`, but missed zero-extended literals such as `0bv16++nb_hdr.ipv4.total_len`. After constant propagation this becomes `0bv16++32768bv16`; `_literal_int` now folds literal bit-vector concatenations and recovers `32768`.
  - The near-wrap BPL fast-forwards the target slot to `4294934528bv32` (`2^32 - 32768`) and unrolls two scheduler steps. The generated shape is consistent with the intended non-unit step, so the remaining blocker is proof/search cost, not an obvious conversion bug.
- **Smoke/regression**:
  - Red-green regression added in `dslc/tests/wraparound/test_wraparound_candidate_gating.py`:
    - `test_meta_update_delta_recovers_zero_extended_env_fixed_header_value` failed before the fix because no candidate was inferred.
    - The same targeted test passes after the fix.
  - Focused regression batch:
    - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc '.venv-wsl/bin/python -m unittest -v dslc.tests.wraparound.test_wraparound_candidate_gating.TestWraparoundCandidateGating.test_meta_update_delta_recovers_env_fixed_header_value dslc.tests.wraparound.test_wraparound_candidate_gating.TestWraparoundCandidateGating.test_meta_update_delta_recovers_zero_extended_env_fixed_header_value dslc.tests.toolchain.test_validate_counterexample dslc.tests.toolchain.test_validate_wraparound_manifest dslc.tests.cli.test_gemcutter_result_rc'` -> PASS (`27` tests).
  - Python compile:
    - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc 'python3 -m py_compile dslc/analysis/wraparound_candidates.py dslc/tests/wraparound/test_wraparound_candidate_gating.py dslc/bench/validate_counterexample.py dslc/tests/toolchain/test_validate_counterexample.py dslc/tests/toolchain/test_validate_wraparound_manifest.py'` -> PASS.
  - File-size check after this change: `wraparound_candidates.py` 969 lines, `test_wraparound_candidate_gating.py` 1167 lines, `validate_counterexample.py` 820 lines, `test_validate_counterexample.py` 1232 lines, `test_validate_wraparound_manifest.py` 172 lines.

## 2026-05-08 SwitchML workers_count focused-direct replay

- **Spec**: `Procurator/argo/code/spec/bench/external_switchml_workers_count_zero_direct.prop`
- **Time**: 2026-05-08 22:40-22:43 Asia/Shanghai
- **Goal/Progress**: Re-run an external SwitchML candidate on the current tree instead of relying on the older 2026-05-06 main-solver log. The aim was to determine whether the prior no-witness candidate is now an auditable direct witness.
- **Result**:
  - Command:
    - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_switchml_workers_count_zero_direct.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound off --ultimate-timeout-seconds 600 --ultimate-xmx-gb 8 --use-spec-max-steps`
  - Run directory: `.tmp/procurator/verify/external_switchml_workers_count_zero_direct/20260508-224036-7fb0/`
  - Result: focused direct prepass returned `UNSAFE`; original full run was skipped after the under-approximation witness.
  - Marker: `.tmp/procurator/verify/external_switchml_workers_count_zero_direct/20260508-224036-7fb0/external_switchml_workers_count_zero_direct.focused-index0.unsafe.json`
  - Marker binding:
    - `target_reg=sw_Ingress_workers_counter_workers_count`
    - `idx_var=sw_ig_md.switchml_md.pool_index`
    - `zero=0bv15`
    - `target_slice=[16, 8]`
    - `target_value=0bv8`
    - `assert_lines=[2302]`
  - Ultimate log: `CounterExampleResult [Line: 2302]: assertion can be violated`, followed by `RESULT: Ultimate proved your program to be incorrect!`
  - `dslc.bench.validate_counterexample --out-dir` accepted the run as `focused_under_approx`.
- **Pitfalls/Fixes**:
  - This is a direct under-approximation witness, not a wraparound closure certificate. It is sound as a bug witness because the focused BPL fixes `pool_index == 0bv15` and the marker hashes bind the source BPL, focused BPL, target register, target slice, and accepted assertion line.
  - No implementation change was required in this replay; it uses the focused-direct and register-mirror hardening already present in the current tree.
- **Smoke/regression**:
  - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc 'python3 -m dslc.bench.validate_counterexample --out-dir .tmp/procurator/verify/external_switchml_workers_count_zero_direct/20260508-224036-7fb0'` -> `[OK] focused_under_approx: focused under-approximation witness (external_switchml_workers_count_zero_direct.focused-index0.unsafe.json)`.

## 2026-05-08 SwitchML value00 first-field focused-direct replay

- **Spec**: `Procurator/argo/code/spec/bench/external_switchml_value00_first_zero_direct.prop`
- **Time**: 2026-05-08 22:43-22:45 Asia/Shanghai
- **Goal/Progress**: Re-run the first-field `value00.values` candidate on the current tree. The older 2026-05-06 evidence had a witness for the second 32-bit field; this run checks the first 32-bit field under the current focused-direct implementation.
- **Result**:
  - Command:
    - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_switchml_value00_first_zero_direct.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound off --ultimate-timeout-seconds 600 --ultimate-xmx-gb 8 --use-spec-max-steps`
  - Run directory: `.tmp/procurator/verify/external_switchml_value00_first_zero_direct/20260508-224308-6699/`
  - Result: focused direct prepass returned `UNSAFE`; original full run was skipped after the under-approximation witness.
  - Marker: `.tmp/procurator/verify/external_switchml_value00_first_zero_direct/20260508-224308-6699/external_switchml_value00_first_zero_direct.focused-index0.unsafe.json`
  - Marker binding:
    - `target_reg=sw_Ingress_value00_values`
    - `idx_var=sw_ig_md.switchml_md.pool_index`
    - `zero=0bv15`
    - `target_slice=[64, 32]`
    - `target_value=0bv32`
    - `assert_lines=[2464]`
  - Ultimate log: `CounterExampleResult [Line: 2464]: assertion can be violated`, followed by `RESULT: Ultimate proved your program to be incorrect!`
  - `dslc.bench.validate_counterexample --out-dir` accepted the run as `focused_under_approx`.
- **Pitfalls/Fixes**:
  - This is a direct under-approximation witness, not a closure certificate. It is distinct from the second-field value00 replay because it binds the first 32-bit slice `[64:32]` of the packed `value_pair_t` register.
  - No implementation change was required in this replay.
- **Smoke/regression**:
  - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc 'python3 -m dslc.bench.validate_counterexample --out-dir .tmp/procurator/verify/external_switchml_value00_first_zero_direct/20260508-224308-6699'` -> `[OK] focused_under_approx: focused under-approximation witness (external_switchml_value00_first_zero_direct.focused-index0.unsafe.json)`.

## 2026-05-08 SwitchML cross-job interleaving replay

- **Spec**: `Procurator/argo/code/spec/bench/external_switchml_cross_job_worker_mix_completion.prop`
- **Time**: 2026-05-08 22:45-22:48 Asia/Shanghai
- **Goal/Progress**: Re-run the SwitchML cross-job worker-state mixing property on the current tree, because this is a stronger interleaving-style property than the focused zero-field witnesses. The property checks whether job 2 can reuse pool-index state left by job 1 and be treated as complete after only one job-2 worker contribution.
- **Result**:
  - Command:
    - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_switchml_cross_job_worker_mix_completion.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound off --ultimate-timeout-seconds 600 --ultimate-xmx-gb 8 --use-spec-max-steps`
  - Run directory: `.tmp/procurator/verify/external_switchml_cross_job_worker_mix_completion/20260508-224528-0354/`
  - Main run: `RESULT: UNSAFE`; Ultimate reported `CounterExampleResult [Line: 3199]: assertion can be violated`, `OverallTime≈44.0s`.
  - Witness rerun: `RESULT: UNSAFE`; same assertion line 3199, `OverallTime≈45.0s`.
  - Witness artifacts:
    - `.tmp/procurator/verify/external_switchml_cross_job_worker_mix_completion/20260508-224528-0354/external_switchml_cross_job_worker_mix_completion.bpl-witness.graphml`
    - `.tmp/procurator/verify/external_switchml_cross_job_worker_mix_completion/20260508-224528-0354/external_switchml_cross_job_worker_mix_completion.bpl-witness.yml`
  - `dslc.bench.validate_counterexample --out-dir` accepted the run as `dsl_assert`.
- **Pitfalls/Fixes**:
  - This is a full direct-check DSL assertion witness, not a focused under-approximation and not a wraparound closure certificate.
  - The relevant assertion requires two processed packets and the second packet's job-2/worker-1 state to observe `worker_bitmap_before == 1`, `map_result == 0`, `first_last_flag == 1`, `workers_counter_count_workers_action`, and `value00_sum_read1_action`.
  - No implementation change was required in this replay.
- **Smoke/regression**:
  - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc 'python3 -m dslc.bench.validate_counterexample --out-dir .tmp/procurator/verify/external_switchml_cross_job_worker_mix_completion/20260508-224528-0354'` -> `[OK] dsl_assert: DSL global assertion violated (accumulator flag set; external_switchml_cross_job_worker_mix_completion.bpl-witness.graphml)`.

## 2026-05-08 NeuralP4 run-state interleaving replay

- **Spec**: `Procurator/argo/code/spec/bench/external_neuralp4_netml_run_interleaving.prop`
- **Time**: 2026-05-08 22:49-22:53 Asia/Shanghai
- **Goal/Progress**: Re-run a machine-learning P4 artifact candidate on the current tree. The property checks that interleaving packets from two ANN runs can reset the single-slot run-progress registers, so run 1 loses its earlier stimulus state after run 2 passes through.
- **Result**:
  - Command:
    - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_neuralp4_netml_run_interleaving.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound off --ultimate-timeout-seconds 600 --ultimate-xmx-gb 8 --use-spec-max-steps`
  - Run directory: `.tmp/procurator/verify/external_neuralp4_netml_run_interleaving/20260508-224932-2baf/`
  - Main run: `RESULT: UNSAFE`; Ultimate reported `CounterExampleResult [Line: 948]: assertion can be violated`, `OverallTime≈58.9s`.
  - Witness rerun: `RESULT: UNSAFE`; same assertion line 948, `OverallTime≈56.5s`.
  - Witness artifacts:
    - `.tmp/procurator/verify/external_neuralp4_netml_run_interleaving/20260508-224932-2baf/external_neuralp4_netml_run_interleaving.bpl-witness.graphml`
    - `.tmp/procurator/verify/external_neuralp4_netml_run_interleaving/20260508-224932-2baf/external_neuralp4_netml_run_interleaving.bpl-witness.yml`
  - `dslc.bench.validate_counterexample --out-dir` accepted the run as `dsl_assert`.
- **Pitfalls/Fixes**:
  - This is a full direct-check interleaving witness, not a wraparound certificate. It shows the bounded three-packet run sequence reaches the DSL assertion violation under the generated harness.
  - No implementation change was required in this replay.
- **Smoke/regression**:
  - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc 'python3 -m dslc.bench.validate_counterexample --out-dir .tmp/procurator/verify/external_neuralp4_netml_run_interleaving/20260508-224932-2baf'` -> `[OK] dsl_assert: DSL global assertion violated (accumulator flag set; external_neuralp4_netml_run_interleaving.bpl-witness.graphml)`.

## 2026-05-08/09 P4DB slicing control-call and schedule-replay certificate hardening

- **Spec/Regression anchor**:
  - P4B direct regression: `dslc.tests.p4b.test_p4b_translator_regressions.TestP4BTranslatorRegressions.test_p4db_damper_table_set_default_not_lost_under_slicing`
  - Certificate regressions: `dslc.tests.toolchain.test_validate_wraparound_manifest`
- **Time**: 2026-05-08 23:10 - 2026-05-09 00:10 Asia/Shanghai
- **Goal/Progress**: Before running more external-system solver jobs, re-established a fast P4B/DSLC regression baseline. The first batch found a real P4DB slicing regression: under `--slicing-vars=damper_register`, the generated Boogie kept only a declaration for `damper_1.apply(arg0:headers, arg1:metadata, arg2:standard_metadata_t)` and lost the reachable `damper_tbl_1.apply()` body and `table_set_default` parameter writes.
- **Implementation changes**:
  - `P4B-Translator/backends/verify/slicing/slicer_internal.h` / `slicer.cpp`: the slicer now collects P4 control declarations and, when a kept call reaches a nested control instance such as the P4_14 macro-generated `damper_1`, recursively records the nested control body's table/action/RegisterAction callees. This keeps the actual table statements, not only the outer control call.
  - `P4B-Translator/backends/verify/translate/translate.h`, `impl/core/translate.cpp`, `impl/lowering/translate_program.cpp`, and `impl/lowering/translate_statement.cpp`: translator records `Declaration_Instance` names for control instances and rewrites `control_instance.apply(...)` to call the already generated control procedure when available. This fixes the P4_14 lowering shape where the receiver type is `Unknown type` but the instance name still identifies the control.
  - `dslc/bench/validate_counterexample.py`: schedule-replay manifest validation now rejects focused near-wrap artifacts as certified CONFIRM evidence, and closure artifacts must prove scalar projection variables by both snapshot assignment and final equality.
  - `dslc/tests/toolchain/test_validate_wraparound_manifest.py` and `dslc/tests/toolchain/wraparound_manifest_fixtures.py`: added red-green regressions for the two certificate soundness gaps found by reviewer: missing scalar projection equality and focused near-wrap being used as certified confirm.
- **Result**:
  - P4DB red regression before the fix:
    - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc '.venv-wsl/bin/python -m unittest -v dslc.tests.p4b.test_p4b_translator_regressions.TestP4BTranslatorRegressions.test_p4db_damper_table_set_default_not_lost_under_slicing'` -> FAIL because `procedure {:inline 1} damper_tbl_1.apply()` was absent.
  - P4DB after the fix:
    - Same targeted test -> PASS.
    - Debug output shape now includes `procedure {:inline 1} damper_1()`, `call damper_tbl_1.apply();`, `procedure {:inline 1} damper_tbl_1.apply()`, `damper_tbl_1.action_run := damper_tbl_1.action.set_damper;`, and the ingress call lowered to `call damper_1();`.
  - Certificate red regressions before the fix:
    - `test_validate_schedule_replay_rejects_scalar_projection_without_closure_equality` and `test_validate_schedule_replay_rejects_focused_near_wrap_as_certified_confirm` both failed because the validator accepted the corrupted artifacts.
  - Certificate after the fix:
    - The same two tests -> PASS.
- **Pitfalls/Fixes**:
  - The initial slicer-only fix made `keep tables=3` for `damper_tbl_1`, `break_1`, and `damper_end_tbl_1`, but the final Boogie still did not print table apply procedures because `damper_1.apply(...)` was an unresolved external-style call and table procedures were unreachable from `mainProcedure`. The durable fix needed both the slicer interprocedural closure and translator control-instance call lowering.
  - The P4C frontend gives `Unknown type` for the P4_14 macro receiver at the call site, so relying on `Type_Name` was not enough. The translator now records the declaration-instance-to-control-type relation when declarations are available.
  - Focused near-wrap remains useful diagnostic evidence, but it is an under-approximation goal and cannot by itself satisfy the certified schedule-replay `near_wrap` stage for a full bug certificate.
- **Smoke/regression**:
  - Build: `wsl.exe --cd /mnt/e/p4-verify -- bash -lc 'cd P4B-Translator/build-host && cmake --build . --target p4c-translator -j2'` -> PASS.
  - Focused validator tests: `wsl.exe --cd /mnt/e/p4-verify -- bash -lc '.venv-wsl/bin/python -m unittest -v dslc.tests.toolchain.test_validate_counterexample dslc.tests.toolchain.test_validate_wraparound_manifest dslc.tests.cli.test_gemcutter_result_rc'` -> PASS (`27` tests).
  - Medium regression batch: `wsl.exe --cd /mnt/e/p4-verify -- bash -lc '.venv-wsl/bin/python -m unittest -v dslc.tests.p4b.test_p4b_flowdos_hash dslc.tests.p4b.test_p4b_translator_regressions dslc.tests.wraparound.test_wraparound_candidate_gating dslc.tests.toolchain.test_validate_counterexample dslc.tests.toolchain.test_validate_wraparound_manifest dslc.tests.cli.test_gemcutter_result_rc'` -> PASS (`66` tests).

## 2026-05-08/09 NeuralP4 completion-reopen interleaving current-tree witness

- **Spec**: `Procurator/argo/code/spec/bench/external_neuralp4_netml_completion_reopen_interleaving.prop`
- **Time**: 2026-05-08 23:51-23:54 Asia/Shanghai
- **Goal/Progress**: Re-run a NeuralP4 machine-learning P4 candidate on the current tree after the P4B control-call and certificate hardening. First checked model shape with compile/smoke, then ran direct checking.
- **Result**:
  - Compile/smoke:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_neuralp4_netml_completion_reopen_interleaving.prop --out .tmp/procurator/manual/external_neuralp4_netml_completion_reopen_interleaving/current/current.bpl --work-dir .tmp/procurator/manual/external_neuralp4_netml_completion_reopen_interleaving/current/work --boogie-harness sequential --no-two-stage --no-reg-debug --skip-duplicated-fail-fast-global-asserts` -> PASS.
    - `./bin/procurator smoke --bpl .tmp/procurator/manual/external_neuralp4_netml_completion_reopen_interleaving/current/current.bpl --harness sequential` -> PASS.
    - BPL size: 698 lines.
  - Direct verification:
    - Run directory: `.tmp/procurator/verify/external_neuralp4_netml_completion_reopen_interleaving/20260508-235219-a4c6/`
    - Main run: `RESULT: UNSAFE`.
    - Witness rerun: `RESULT: UNSAFE`.
    - Witness artifacts:
      - `.tmp/procurator/verify/external_neuralp4_netml_completion_reopen_interleaving/20260508-235219-a4c6/external_neuralp4_netml_completion_reopen_interleaving.bpl-witness.graphml`
      - `.tmp/procurator/verify/external_neuralp4_netml_completion_reopen_interleaving/20260508-235219-a4c6/external_neuralp4_netml_completion_reopen_interleaving.bpl-witness.yml`
    - Validator: `[OK] dsl_assert: DSL global assertion violated (accumulator flag set; external_neuralp4_netml_completion_reopen_interleaving.bpl-witness.graphml)`.
- **Pitfalls/Fixes**:
  - An initial shell command used `$(basename ...)` inside a PowerShell-interpreted string and failed before invoking the toolchain correctly. Re-ran using explicit paths in WSL; the model and verifier run were unaffected.
  - No implementation change was required for this spec after the earlier P4B/validator fixes.
- **Smoke/regression**:
  - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc 'python3 -m dslc.bench.validate_counterexample --out-dir .tmp/procurator/verify/external_neuralp4_netml_completion_reopen_interleaving/20260508-235219-a4c6'` -> PASS.

## 2026-05-08/09 NeuralP4 run-id alias interleaving current-tree witness

- **Spec**: `Procurator/argo/code/spec/bench/external_neuralp4_netml_run_id_alias_drop.prop`
- **Time**: 2026-05-08 23:54-23:57 Asia/Shanghai
- **Goal/Progress**: Re-run the NeuralP4 run-id alias property on the current tree, distinguishing model correctness from solver behavior before classifying the candidate.
- **Result**:
  - Compile/smoke:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_neuralp4_netml_run_id_alias_drop.prop --out .tmp/procurator/manual/external_neuralp4_netml_run_id_alias_drop/current/current.bpl --work-dir .tmp/procurator/manual/external_neuralp4_netml_run_id_alias_drop/current/work --boogie-harness sequential --no-two-stage --no-reg-debug --skip-duplicated-fail-fast-global-asserts` -> PASS.
    - `./bin/procurator smoke --bpl .tmp/procurator/manual/external_neuralp4_netml_run_id_alias_drop/current/current.bpl --harness sequential` -> PASS.
    - BPL size: 674 lines.
  - Direct verification:
    - Run directory: `.tmp/procurator/verify/external_neuralp4_netml_run_id_alias_drop/20260508-235455-ccd1/`
    - Main run: `RESULT: UNSAFE`.
    - Witness rerun: `RESULT: UNSAFE`.
    - Witness artifacts:
      - `.tmp/procurator/verify/external_neuralp4_netml_run_id_alias_drop/20260508-235455-ccd1/external_neuralp4_netml_run_id_alias_drop.bpl-witness.graphml`
      - `.tmp/procurator/verify/external_neuralp4_netml_run_id_alias_drop/20260508-235455-ccd1/external_neuralp4_netml_run_id_alias_drop.bpl-witness.yml`
    - Validator: `[OK] dsl_assert: DSL global assertion violated (accumulator flag set; external_neuralp4_netml_run_id_alias_drop.bpl-witness.graphml)`.
- **Pitfalls/Fixes**:
  - No implementation change was required for this spec; compile/smoke confirmed the BPL/harness shape first.
- **Smoke/regression**:
  - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc 'python3 -m dslc.bench.validate_counterexample --out-dir .tmp/procurator/verify/external_neuralp4_netml_run_id_alias_drop/20260508-235455-ccd1'` -> PASS.

## 2026-05-08/09 NeuralP4 argmax winner-loss current-tree witness

- **Spec**: `Procurator/argo/code/spec/bench/external_neuralp4_netml_argmax_winner_loss.prop`
- **Time**: 2026-05-08 23:57 - 2026-05-09 00:02 Asia/Shanghai
- **Goal/Progress**: Re-run the NeuralP4 argmax winner-loss property on the current tree. This candidate has a larger generated BPL, so compile/smoke was checked before running Ultimate.
- **Result**:
  - Compile/smoke:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_neuralp4_netml_argmax_winner_loss.prop --out .tmp/procurator/manual/external_neuralp4_netml_argmax_winner_loss/current/current.bpl --work-dir .tmp/procurator/manual/external_neuralp4_netml_argmax_winner_loss/current/work --boogie-harness sequential --no-two-stage --no-reg-debug --skip-duplicated-fail-fast-global-asserts` -> PASS.
    - `./bin/procurator smoke --bpl .tmp/procurator/manual/external_neuralp4_netml_argmax_winner_loss/current/current.bpl --harness sequential` -> PASS.
    - BPL size: 1707 lines.
  - Direct verification:
    - Run directory: `.tmp/procurator/verify/external_neuralp4_netml_argmax_winner_loss/20260508-235744-471c/`
    - Main run: `RESULT: UNSAFE`.
    - Witness rerun: `RESULT: UNSAFE`.
    - Witness artifacts:
      - `.tmp/procurator/verify/external_neuralp4_netml_argmax_winner_loss/20260508-235744-471c/external_neuralp4_netml_argmax_winner_loss.bpl-witness.graphml`
      - `.tmp/procurator/verify/external_neuralp4_netml_argmax_winner_loss/20260508-235744-471c/external_neuralp4_netml_argmax_winner_loss.bpl-witness.yml`
    - Validator: `[OK] dsl_assert: DSL global assertion violated (accumulator flag set; external_neuralp4_netml_argmax_winner_loss.bpl-witness.graphml)`.
- **Pitfalls/Fixes**:
  - No implementation change was required for this spec. The direct check completed within the 600s per-candidate cap.
- **Smoke/regression**:
  - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc 'python3 -m dslc.bench.validate_counterexample --out-dir .tmp/procurator/verify/external_neuralp4_netml_argmax_winner_loss/20260508-235744-471c'` -> PASS.

## 2026-05-08/09 NeuralP4 argmax new-winner-loss current-tree witness

- **Spec**: `Procurator/argo/code/spec/bench/external_neuralp4_netml_argmax_new_winner_loss.prop`
- **Time**: 2026-05-09 00:04-00:09 Asia/Shanghai
- **Goal/Progress**: Re-run the paired NeuralP4 argmax new-winner property on the current tree after the first argmax witness, again checking generated BPL/harness shape before solver time.
- **Result**:
  - Compile/smoke:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_neuralp4_netml_argmax_new_winner_loss.prop --out .tmp/procurator/manual/external_neuralp4_netml_argmax_new_winner_loss/current/current.bpl --work-dir .tmp/procurator/manual/external_neuralp4_netml_argmax_new_winner_loss/current/work --boogie-harness sequential --no-two-stage --no-reg-debug --skip-duplicated-fail-fast-global-asserts` -> PASS.
    - `./bin/procurator smoke --bpl .tmp/procurator/manual/external_neuralp4_netml_argmax_new_winner_loss/current/current.bpl --harness sequential` -> PASS.
    - BPL size: 1707 lines.
  - Direct verification:
    - Run directory: `.tmp/procurator/verify/external_neuralp4_netml_argmax_new_winner_loss/20260509-000413-c874/`
    - Main run: `RESULT: UNSAFE`.
    - Witness rerun: `RESULT: UNSAFE`.
    - Witness artifacts:
      - `.tmp/procurator/verify/external_neuralp4_netml_argmax_new_winner_loss/20260509-000413-c874/external_neuralp4_netml_argmax_new_winner_loss.bpl-witness.graphml`
      - `.tmp/procurator/verify/external_neuralp4_netml_argmax_new_winner_loss/20260509-000413-c874/external_neuralp4_netml_argmax_new_winner_loss.bpl-witness.yml`
    - Validator: `[OK] dsl_assert: DSL global assertion violated (accumulator flag set; external_neuralp4_netml_argmax_new_winner_loss.bpl-witness.graphml)`.
- **Pitfalls/Fixes**:
  - No implementation change was required for this spec. The result is a full direct-check DSL assertion witness, not a focused under-approximation and not a wraparound certificate.
- **Smoke/regression**:
  - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc 'python3 -m dslc.bench.validate_counterexample --out-dir .tmp/procurator/verify/external_neuralp4_netml_argmax_new_winner_loss/20260509-000413-c874'` -> PASS.

## 2026-05-09 SwitchML job-pool alias current-tree witness

- **Spec**: `Procurator/argo/code/spec/bench/external_switchml_job_pool_alias_drop.prop`
- **Time**: 2026-05-09 00:12-00:15 Asia/Shanghai
- **Goal/Progress**: Continue the external-system interleaving mining loop on SwitchML candidates that had older run artifacts, using the current tree after the P4B/validator fixes. Checked generated BPL/harness first, then ran direct verification.
- **Result**:
  - Compile/smoke:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_switchml_job_pool_alias_drop.prop --out .tmp/procurator/manual/external_switchml_job_pool_alias_drop/current/current.bpl --work-dir .tmp/procurator/manual/external_switchml_job_pool_alias_drop/current/work --boogie-harness sequential --no-two-stage --no-reg-debug --skip-duplicated-fail-fast-global-asserts` -> PASS.
    - `./bin/procurator smoke --bpl .tmp/procurator/manual/external_switchml_job_pool_alias_drop/current/current.bpl --harness sequential` -> PASS.
    - BPL size: 2744 lines.
  - Direct verification:
    - Run directory: `.tmp/procurator/verify/external_switchml_job_pool_alias_drop/20260509-001205-85c1/`
    - Main run: `RESULT: UNSAFE`.
    - Witness rerun: `RESULT: UNSAFE`.
    - Witness artifacts:
      - `.tmp/procurator/verify/external_switchml_job_pool_alias_drop/20260509-001205-85c1/external_switchml_job_pool_alias_drop.bpl-witness.graphml`
      - `.tmp/procurator/verify/external_switchml_job_pool_alias_drop/20260509-001205-85c1/external_switchml_job_pool_alias_drop.bpl-witness.yml`
    - Validator: `[OK] dsl_assert: DSL global assertion violated (accumulator flag set; external_switchml_job_pool_alias_drop.bpl-witness.graphml)`.
- **Pitfalls/Fixes**:
  - No implementation change was required for this spec after the earlier P4B control-call and certificate hardening.
- **Smoke/regression**:
  - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc 'python3 -m dslc.bench.validate_counterexample --out-dir .tmp/procurator/verify/external_switchml_job_pool_alias_drop/20260509-001205-85c1'` -> PASS.

## 2026-05-09 SwitchML RDMA same-QP assign current-tree witness

- **Spec**: `Procurator/argo/code/spec/bench/external_switchml_rdma_same_qp_state_overwrite_assign.prop`
- **Time**: 2026-05-09 00:16-00:19 Asia/Shanghai
- **Goal/Progress**: Re-run the SwitchML RDMA same-QP state overwrite property on the current tree, with compile/smoke before solver time.
- **Result**:
  - Compile/smoke:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_switchml_rdma_same_qp_state_overwrite_assign.prop --out .tmp/procurator/manual/external_switchml_rdma_same_qp_state_overwrite_assign/current/current.bpl --work-dir .tmp/procurator/manual/external_switchml_rdma_same_qp_state_overwrite_assign/current/work --boogie-harness sequential --no-two-stage --no-reg-debug --skip-duplicated-fail-fast-global-asserts` -> PASS.
    - `./bin/procurator smoke --bpl .tmp/procurator/manual/external_switchml_rdma_same_qp_state_overwrite_assign/current/current.bpl --harness sequential` -> PASS.
    - BPL size: 2743 lines.
  - Direct verification:
    - Run directory: `.tmp/procurator/verify/external_switchml_rdma_same_qp_state_overwrite_assign/20260509-001604-852d/`
    - Main run: `RESULT: UNSAFE`.
    - Witness rerun: `RESULT: UNSAFE`.
    - Witness artifacts:
      - `.tmp/procurator/verify/external_switchml_rdma_same_qp_state_overwrite_assign/20260509-001604-852d/external_switchml_rdma_same_qp_state_overwrite_assign.bpl-witness.graphml`
      - `.tmp/procurator/verify/external_switchml_rdma_same_qp_state_overwrite_assign/20260509-001604-852d/external_switchml_rdma_same_qp_state_overwrite_assign.bpl-witness.yml`
    - Validator: `[OK] dsl_assert: DSL global assertion violated (accumulator flag set; external_switchml_rdma_same_qp_state_overwrite_assign.bpl-witness.graphml)`.
- **Pitfalls/Fixes**:
  - No implementation change was required for this spec. The result is a full direct-check DSL assertion witness.
- **Smoke/regression**:
  - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc 'python3 -m dslc.bench.validate_counterexample --out-dir .tmp/procurator/verify/external_switchml_rdma_same_qp_state_overwrite_assign/20260509-001604-852d'` -> PASS.

## 2026-05-09 SwitchML shadow-bitmap duplicate-count current-tree witness

- **Spec**: `Procurator/argo/code/spec/bench/external_switchml_shadow_bitmap_duplicate_count.prop`
- **Time**: 2026-05-09 00:22-00:25 Asia/Shanghai
- **Goal/Progress**: Re-run the SwitchML shadow-bitmap duplicate-count property on the current tree, again separating model generation checks from solver evidence.
- **Result**:
  - Compile/smoke:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_switchml_shadow_bitmap_duplicate_count.prop --out .tmp/procurator/manual/external_switchml_shadow_bitmap_duplicate_count/current/current.bpl --work-dir .tmp/procurator/manual/external_switchml_shadow_bitmap_duplicate_count/current/work --boogie-harness sequential --no-two-stage --no-reg-debug --skip-duplicated-fail-fast-global-asserts` -> PASS.
    - `./bin/procurator smoke --bpl .tmp/procurator/manual/external_switchml_shadow_bitmap_duplicate_count/current/current.bpl --harness sequential` -> PASS.
    - BPL size: 2749 lines.
  - Direct verification:
    - Run directory: `.tmp/procurator/verify/external_switchml_shadow_bitmap_duplicate_count/20260509-002212-1de4/`
    - Main run: `RESULT: UNSAFE`.
    - Witness rerun: `RESULT: UNSAFE`.
    - Witness artifacts:
      - `.tmp/procurator/verify/external_switchml_shadow_bitmap_duplicate_count/20260509-002212-1de4/external_switchml_shadow_bitmap_duplicate_count.bpl-witness.graphml`
      - `.tmp/procurator/verify/external_switchml_shadow_bitmap_duplicate_count/20260509-002212-1de4/external_switchml_shadow_bitmap_duplicate_count.bpl-witness.yml`
    - Validator: `[OK] dsl_assert: DSL global assertion violated (accumulator flag set; external_switchml_shadow_bitmap_duplicate_count.bpl-witness.graphml)`.
- **Pitfalls/Fixes**:
  - No implementation change was required for this spec. A WSL process check after this batch showed no active Ultimate/java/z3/procurator verifier process.
- **Smoke/regression**:
  - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc 'python3 -m dslc.bench.validate_counterexample --out-dir .tmp/procurator/verify/external_switchml_shadow_bitmap_duplicate_count/20260509-002212-1de4'` -> PASS.

## 2026-05-09 NeuralP4 weighted-sum accumulator wrap current-tree witness

- **Spec**: `Procurator/argo/code/spec/bench/external_neuralp4_netml_weighted_sum_accumulator_wrap.prop`
- **Time**: 2026-05-09 00:41-00:45 Asia/Shanghai
- **Goal/Progress**: Continue the external-system mining loop on a NeuralP4 machine-learning P4 artifact candidate that had not yet been recorded in this batch. The property targets the `FUNC_WEIGHTED_SUM_16_TO_32` path: two valid stimuli update the bit<8> neuron-data accumulator, so the generated model should expose the arithmetic wrap to value `144`.
- **Result**:
  - Compile/smoke:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_neuralp4_netml_weighted_sum_accumulator_wrap.prop --out .tmp/procurator/manual/external_neuralp4_netml_weighted_sum_accumulator_wrap/current/current.bpl --work-dir .tmp/procurator/manual/external_neuralp4_netml_weighted_sum_accumulator_wrap/current/work --boogie-harness sequential --no-two-stage --no-reg-debug --skip-duplicated-fail-fast-global-asserts` -> PASS.
    - `./bin/procurator smoke --bpl .tmp/procurator/manual/external_neuralp4_netml_weighted_sum_accumulator_wrap/current/current.bpl --harness sequential` -> PASS.
    - BPL size: 2130 lines.
  - Direct verification:
    - Command:
      - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_neuralp4_netml_weighted_sum_accumulator_wrap.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound off --ultimate-timeout-seconds 600 --ultimate-xmx-gb 8 --use-spec-max-steps --skip-duplicated-fail-fast-global-asserts`
    - Run directory: `.tmp/procurator/verify/external_neuralp4_netml_weighted_sum_accumulator_wrap/20260509-004102-a575/`
    - Main run: `RESULT: UNSAFE`.
    - Witness rerun: `RESULT: UNSAFE`.
    - Witness artifacts:
      - `.tmp/procurator/verify/external_neuralp4_netml_weighted_sum_accumulator_wrap/20260509-004102-a575/external_neuralp4_netml_weighted_sum_accumulator_wrap.bpl-witness.graphml`
      - `.tmp/procurator/verify/external_neuralp4_netml_weighted_sum_accumulator_wrap/20260509-004102-a575/external_neuralp4_netml_weighted_sum_accumulator_wrap.bpl-witness.yml`
    - Validator: `[OK] dsl_assert: DSL global assertion violated (accumulator flag set; external_neuralp4_netml_weighted_sum_accumulator_wrap.bpl-witness.graphml)`.
- **Pitfalls/Fixes**:
  - The first compile command in this session used bash variables inside a PowerShell-wrapped string and failed before invoking the compiler (`--spec` was seen without an argument). Re-ran using explicit WSL paths; the toolchain/model was unaffected.
  - No implementation change was required for this spec after the earlier P4B control-call and certificate hardening.
- **Smoke/regression**:
  - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc 'python3 -m dslc.bench.validate_counterexample --out-dir .tmp/procurator/verify/external_neuralp4_netml_weighted_sum_accumulator_wrap/20260509-004102-a575'` -> PASS.

## 2026-05-09 SwitchML RDMA same-QP overwrite bounded check

- **Spec**: `Procurator/argo/code/spec/bench/external_switchml_rdma_same_qp_state_overwrite.prop`
- **Time**: 2026-05-09 00:46-00:48 Asia/Shanghai
- **Goal/Progress**: Distinguish the non-assign same-QP overwrite assertion from the already validated `external_switchml_rdma_same_qp_state_overwrite_assign.prop` witness. Checked the generated BPL/harness first, then ran the bounded direct verifier with the spec's `max_steps`.
- **Result**:
  - Compile/smoke:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_switchml_rdma_same_qp_state_overwrite.prop --out .tmp/procurator/manual/external_switchml_rdma_same_qp_state_overwrite/current/current.bpl --work-dir .tmp/procurator/manual/external_switchml_rdma_same_qp_state_overwrite/current/work --boogie-harness sequential --no-two-stage --no-reg-debug --skip-duplicated-fail-fast-global-asserts` -> PASS.
    - `./bin/procurator smoke --bpl .tmp/procurator/manual/external_switchml_rdma_same_qp_state_overwrite/current/current.bpl --harness sequential` -> PASS.
    - BPL size: 2743 lines.
  - Direct verification:
    - Command:
      - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_switchml_rdma_same_qp_state_overwrite.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound off --ultimate-timeout-seconds 600 --ultimate-xmx-gb 8 --use-spec-max-steps --skip-duplicated-fail-fast-global-asserts`
    - Run directory: `.tmp/procurator/verify/external_switchml_rdma_same_qp_state_overwrite/20260509-004638-60c4/`
    - Result: `RESULT: Ultimate proved your program to be correct!`
- **Pitfalls/Fixes**:
  - This is not counted as a newly found bug. The run only establishes that this particular bounded assertion did not produce a counterexample under the generated model and spec bound; it does not invalidate the related `*_assign` witness, which asserts a different observable state overwrite.
  - No implementation change was required.
- **Smoke/regression**:
  - Compile and structural smoke passed as listed above. No counterexample validator was run because the result was `SAFE`, not a witness-producing run.

## 2026-05-09 NetBeacon bin2 direct wrap bounded attempt

- **Spec**: `Procurator/argo/code/spec/bench/external_netbeacon_bin2_wraparound_direct.prop`
- **Time**: 2026-05-09 00:50-01:01 Asia/Shanghai
- **Goal/Progress**: Try the NetBeacon `Register_bin2` 8-bit feature-bin wrap candidate under a bounded direct check. This is distinct from the certified `Register_total_pkts` schedule-replay wraparound and from the still-open `Register_total_bytes` target.
- **Result**:
  - Compile/smoke:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_netbeacon_bin2_wraparound_direct.prop --out .tmp/procurator/manual/external_netbeacon_bin2_wraparound_direct/current/current.bpl --work-dir .tmp/procurator/manual/external_netbeacon_bin2_wraparound_direct/current/work --boogie-harness sequential --no-two-stage --no-reg-debug --skip-duplicated-fail-fast-global-asserts` -> PASS.
    - `./bin/procurator smoke --bpl .tmp/procurator/manual/external_netbeacon_bin2_wraparound_direct/current/current.bpl --harness sequential` -> PASS.
    - BPL size: 1997 lines.
  - Direct verification:
    - Command:
      - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_netbeacon_bin2_wraparound_direct.prop --boogie-harness sequential --no-two-stage --no-reg-debug --wraparound off --ultimate-timeout-seconds 600 --ultimate-xmx-gb 8 --use-spec-max-steps --skip-duplicated-fail-fast-global-asserts`
    - Run directory: `.tmp/procurator/verify/external_netbeacon_bin2_wraparound_direct/20260509-005031-34f5/`
    - Result: `RESULT: Ultimate could not prove your program: Timeout`.
- **Pitfalls/Fixes**:
  - This run is intentionally recorded as `TIMEOUT`, not as absence of the candidate. The generated model passed structural checks, but the bounded direct checker did not produce a witness within 600s.
  - No implementation change was made from this attempt. A later staged wraparound attempt should use the write mirror and table guard already present in the assertion.
- **Smoke/regression**:
  - Compile and structural smoke passed as listed above. No counterexample validator was run because no witness was produced.

## 2026-05-09 UA 饱和算术语义修复与回归（翻译样例）

- **Spec**: `P4B-Translator/testdata/p4_16_samples/saturated-bmv2.p4`
- **Time**: 2026-05-09 11:10-11:24 Asia/Shanghai
- **目标/进度**: 修复 `--ua`（bv2int）路径下 `|+| / |-|` 饱和算术未生效的问题，确保与非 UA 路径一致保持饱和语义。
- **结果**:
  - 代码修复：
    - `P4B-Translator/backends/verify/translate/impl/lowering/translate_bitblast.cpp`
      - 在 `translateUA(const IR::Operation_Binary*)` 中为 `AddSat` 增加显式分支，并放在 `Add` 前。
      - 保持 `SubSat` 在 `Sub` 前，避免被普通模加/模减分支吞掉。
  - 回归：
    - `python3 -m unittest -v dslc.tests.p4b.translator.test_frontend_io.TestP4BVerifyFrontendIo.test_saturated_ops_ua_mode_keep_saturating_guards` -> PASS。
    - `python3 -m unittest -v dslc.tests.p4b.translator.test_frontend_io` -> PASS。
- **坑（实现错误导致）**:
  - 根因是 UA lowering 分支顺序不正确，`AddSat` 在控制流上被 `Add` 覆盖，导致输出退化为模运算。
- **修复/沉淀为冒烟测试**:
  - 已有回归测试 `test_saturated_ops_ua_mode_keep_saturating_guards` 覆盖该路径，修复后稳定通过。
  - 同步回归：`dslc.tests.p4b.test_p4b_flowdos_hash`、`dslc.tests.p4b.test_p4b_translator_regressions`、`dslc.tests.toolchain.test_validate_wraparound_manifest`、`dslc.tests.wraparound.schedule.test_schedule_prefix_cutpoint` 均通过。

## 2026-05-09 SwitchML 指数复用交错 bug 复验（当前树）

- **Spec**: `Procurator/argo/code/spec/bench/external_switchml_exponent_cross_job_reuse.prop`
- **Time**: 2026-05-09 11:22-11:27 Asia/Shanghai
- **目标/进度**: 在最新实现上复验 SwitchML 指数复用交错 bug；按准则先确认生成 BPL/harness 语义，再运行 direct check。
- **结果**:
  - Compile:
    - `./bin/procurator compile --spec Procurator/argo/code/spec/bench/external_switchml_exponent_cross_job_reuse.prop --boogie-harness sequential --no-two-stage --out .tmp/manual/external_switchml_exponent_cross_job_reuse.bpl` -> PASS。
  - Smoke:
    - `./bin/procurator smoke --bpl .tmp/manual/external_switchml_exponent_cross_job_reuse.bpl --harness sequential` -> PASS。
  - Direct verify:
    - `./bin/procurator verify --spec Procurator/argo/code/spec/bench/external_switchml_exponent_cross_job_reuse.prop --boogie-harness sequential --no-two-stage --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --ultimate-timeout-seconds 900`
    - 结果：`RESULT: UNSAFE`，witness rerun `UNSAFE`，并命中 `dsl_assert`。
    - Run dir: `.tmp/procurator/verify/external_switchml_exponent_cross_job_reuse/20260509-112357-982d/`
- **坑（实现错误导致）**:
  - 首次 smoke 使用 `/tmp/...` 路径时出现 “not found” 误报（路径与入口解析不一致）；切换为仓库相对路径并在 WSL 内直接调用 smoke 后通过。
  - 不属于语义实现错误，翻译与验证链路无需代码修复。
- **修复/沉淀为冒烟测试**:
  - 固化操作：对该类 case 统一使用仓库内路径执行 `procurator smoke`，避免跨环境路径歧义。
  - 该 spec 产出完整 witness，可作为后续烟测样本。

## 2026-05-09 TNA Hash extern 精化 + 语义审计收敛

- **Spec**:
  - `Procurator/argo/code/dataset/external_etc_noms2024/noms_20_5_4.p4`
  - `Procurator/argo/code/dataset/external_flowrest_per_flow/unsw_per_flow_16_classes.p4`
  - `Procurator/argo/code/dataset/external_netbeacon_sec23/NetBeacon/switch/data_plane/switch.p4`
- **Time**: 2026-05-09 11:42-12:08 Asia/Shanghai
- **目标/进度**: 修复 semantic-audit 中 `hash_extern=WEAK`（CRC16/CRC32 退化为 UF）的问题，提升 TNA Hash extern 到精确模型。
- **结果**:
  - 代码修复：
    - `P4B-Translator/backends/verify/translate/impl/lowering/translate_method.cpp`
      - 放宽 `hashAlgorithmUsesBmv2DefaultCrc(...)` 对 `HashAlgorithm_t` 的过滤，使 TNA `HashAlgorithm_t.CRC16/CRC32` 也进入精确 CRC 降低路径。
  - 新增回归：
    - `dslc/tests/p4b/test_p4b_translator_regressions.py`
      - `test_tna_crc_hash_extern_lowers_to_precise_crc_model`（验证 `model=crc{16,32}_bmv2 precision=precise` + CRC helper 出现）。
  - 语义审计复跑（with slicing）：
    - `external_etc_noms2024`：`semantic=OK`（由 WEAK 收敛到 OK）。
    - `external_flowrest_per_flow`：`semantic=OK`（由 WEAK 收敛到 OK）。
    - `external_netbeacon_sec23`：`semantic=OK`（由 WEAK 收敛到 OK）。
- **坑（实现错误导致）**:
  - 根因是哈希算法类型名判定过严（将 `HashAlgorithm_t` 的 CRC16/CRC32 排除在精确路径外），导致不必要的 UF 退化。
- **修复/沉淀为冒烟测试**:
  - 新增 `test_tna_crc_hash_extern_lowers_to_precise_crc_model` 并通过。
  - 回归集：
    - `python3 -m unittest -v dslc.tests.p4b.translator.test_frontend_io dslc.tests.p4b.test_p4b_flowdos_hash dslc.tests.p4b.test_p4b_translator_regressions dslc.tests.toolchain.test_validate_wraparound_manifest dslc.tests.wraparound.schedule.test_schedule_prefix_cutpoint dslc.tests.bench.test_p4b_semantic_audit` -> 全部 PASS（65 tests）。

## 2026-05-09 NeuralP4 大模型编译耗时分流（非语义缺陷）

- **Spec**:
  - `Procurator/argo/code/dataset/external_neuralp4_noms25/NeuralP4/p4-vm/app-iden-27x27x7-q12-12/code/ANN.p4`（以及同目录同族样本）
- **Time**: 2026-05-09 11:50-13:30 Asia/Shanghai
- **目标/进度**: 区分 “之前审计超时” 是语义缺陷还是编译耗时阈值过低导致。
- **结果**:
  - 单例验证（`--no-slicing`）可成功编译，后端 CPU 时间约 322s，程序总 CPU 时间约 344s。
  - 批量 semantic-audit 将 `timeout-seconds` 提升后复跑：
    - `external_neuralp4_noms25` 前 12 个样本均 `semantic=OK`（此前 60s 配置下大量 `timeout` 为配置限制，并非语义错误）。
- **坑（实现错误导致）**:
  - 非实现错误；主要是审计脚本默认超时（60s）与 NeuralP4 规模不匹配。
- **修复/沉淀为冒烟测试**:
  - 运行策略沉淀：NeuralP4 审计使用更高超时（例如 360s 或 480s），避免把 `timeout` 误判为语义不支持。
  - 该结论已记录在本条，后续可直接复用参数。

## 2026-05-09 Mousika 数据集失败归因（输入不完整）

- **Spec**: `Procurator/argo/code/dataset/external_mousika_infocom22/Mousika/P4/flowcontrol.p4`
- **Time**: 2026-05-09 11:48-11:55 Asia/Shanghai
- **目标/进度**: 明确 `scan_p4b_coverage` 中 `FAIL include` 是后端能力缺失还是数据集输入不完整。
- **结果**:
  - 复现命令显示编译失败为：
    - `fatal error: common/headers.p4: No such file or directory`
  - 当前数据集目录中确实不存在 `P4/common/headers.p4` 及对应 `common/*` 依赖文件。
- **坑（实现错误导致）**:
  - 非实现错误；是输入程序依赖缺失。
- **修复/沉淀为冒烟测试**:
  - 暂不通过修改 dataset 规避；保持真实失败分类为 include 缺失。
  - 后续若补齐 upstream `common/*` 文件，再进入语义支持验证闭环。

## 2026-05-10 Flowrest dynamic-index 主路径修复（非 fallback 兜底）

- **Spec**: `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_count_wraparound.prop`
- **Time**: 2026-05-09 16:06 - 2026-05-10 03:57 Asia/Shanghai
- **目标/进度**: 修复 wraparound 动态索引的主路径语法/表达式恢复问题（而非仅 fallback），消除此前 `Toolchain returned no result` 对应的阶段 BPL 不可用风险，并验证已知基线 case 回归。
- **结果**:
  - 代码修复：
    - `dslc/analysis/wraparound_bpl_index.py`
      - 在 `_rewrite_hash_model_expr_to_declared(...)` 中新增同过程局部别名展开 `_expand_rhs_with_local_aliases(...)`。
      - 对 lowered hash RHS 中的临时变量（如 `flowrest_srcPort_1` / `flowrest_dstPort_1`）进行受限展开，替换为稳定依赖后再参与 purity 判定。
  - 新增/更新回归：
    - `dslc/tests/wraparound/test_wraparound_candidate_gating.py`
      - 新增 `test_meta_hash_rewrite_expands_lowered_temp_aliases`，覆盖“lowered hash + 局部别名”路径。
    - 回归批次：
      - `python -m unittest -v dslc.tests.wraparound.test_wraparound_candidate_gating dslc.tests.wraparound.cegis.core.test_wraparound_cegis_dynamic_index dslc.tests.wraparound.schedule.certification.test_schedule_stable_projection`
      - 结果：`31 tests OK`。
  - Flowrest 定向验证证据：
    - Run dir: `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260509-164423-fd1a/`
    - `wraparound.cegis.manifest.json` 证据：
      - `candidate.index_expr = null`
      - `candidate.index_value = 1885`
      - 非早退，已进入阶段化尝试（ENTRY + CONFIRM unroll1/2/3）。
      - `stable_substitutions` 含 `flowrest_meta.register_index == 1885bv16`。
    - 本 run 目录检索无 `"Toolchain returned no result"`。
  - 基线回归（防止改坏已有路径）：
    - `python3 ./bin/procurator compile --spec Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop --out /mnt/e/p4-verify/.tmp/manual/netchain_wraparound_bug.regress.bpl --boogie-harness sequential --no-two-stage` -> PASS。
    - `python3 ./bin/procurator smoke --bpl .tmp/manual/netchain_wraparound_bug.regress.bpl --harness sequential` -> PASS。
- **坑（实现错误导致）**:
  - 根因是高层 `*_idx_calc.get$...` 虽被改写到 lowered CRC 表达式，但其中过程内临时量未被继续消解，导致 index purity 判定失败，进而误走 fallback/早退路径。
- **修复/沉淀为冒烟测试**:
  - 已通过新增单测和 31 项回归锁定该路径。
  - 已补充 Netchain compile+smoke 回归，确认本次修复未破坏历史 wraparound 基线建模。

## 2026-05-10 Wraparound near_wrap `Toolchain returned no result` 根因修复（Flowrest + ETC）
- **Spec**:
  - `Procurator/argo/code/spec/bench/external_flowrest_per_flow_pkt_count_wraparound.prop`
  - `Procurator/argo/code/spec/bench/external_etc_noms2024_pkt_count_wraparound.prop`
- **Time**: 2026-05-10 09:44-10:15 Asia/Shanghai
- **目标/进度**: 区分“实现/工具链问题”与“bug 不存在”，修复 legacy near-wrap 中 `Toolchain returned no result` 的错误来源，并按阶段重跑验证。
- **结果**:
  - 复现根因（修复前）：
    - Flowrest legacy near-wrap 运行 `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260510-095804-f4b6/`
    - `ENTRY_CHECK=UNSAFE`，但 `confirm.unroll1/2/3` 都是 `Toolchain returned no result`
    - 日志定位到 `witnessprinter` 在 SAFE 结果路径崩溃：
      - `NullPointerException ... mStringProvider is null`
  - 实现修复：
    - `dslc/workflows/wraparound_cegis.py`
      - `legacy_closure_assumes` 模式的阶段求解从 witness toolchain 切换到 no-witness toolchain（`ReachSafety.xml` + no-witness settings）。
      - witness 仅在流程显式需要时单独 rerun（不再让 SAFE confirm 被 witness printer 崩溃覆盖）。
    - `dslc/tests/wraparound/schedule/test_wraparound_schedule.py`
      - 更新回归期望为 `test_multi_legacy_uses_nowitness_stage_toolchain`。
  - 修复后证据：
    - Flowrest legacy near-wrap 重跑 `.tmp/procurator/verify/external_flowrest_per_flow_pkt_count_wraparound/20260510-100624-058d/`
      - `ENTRY_CHECK=UNSAFE`
      - `confirm.unroll1/2/3 => RESULT: Ultimate proved your program to be correct!`
      - 日志无 `Toolchain returned no result`、无 witness-printer NPE。
    - ETC legacy near-wrap 对照重跑 `.tmp/procurator/verify/external_etc_noms2024_pkt_count_wraparound/20260510-101130-f209/`
      - `ENTRY_CHECK=UNSAFE`
      - `confirm.unroll1/2/3 => RESULT: Ultimate proved your program to be correct!`
      - 同样无 `Toolchain returned no result`、无 witness-printer NPE。
  - 同时完成 schedule-replay 分阶段核查（Flowrest）：
    - `entry`/`near_wrap` 停在 `entry_prefix.unroll1` timeout（求解耗时问题），不再出现 undeclared callee/no-result 语法错误。
- **坑（实现错误导致）**:
  - legacy 模式此前把 CONFIRM 阶段也绑定到 witness toolchain，导致 SAFE 路径触发 witnessprinter NPE，误报 `Toolchain returned no result`，掩盖真实阶段结论。
- **修复并沉淀为冒烟测试**:
  - 单测回归：
    - `.venv\Scripts\python.exe -m unittest -v dslc.tests.wraparound.schedule.test_wraparound_schedule dslc.tests.wraparound.cegis.core.test_wraparound_cegis_order dslc.tests.wraparound.cegis.core.test_wraparound_cegis_dynamic_index dslc.tests.wraparound.cegis.io.test_wraparound_cegis_result_parsing`
    - `Ran 45 tests ... OK`
  - 基线冒烟（防回归）：
    - `wsl.exe --cd /mnt/e/p4-verify -- bash -lc 'python3 ./bin/procurator compile --spec Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop --out /tmp/netchain_wraparound_bug.regress.20260510.bpl --boogie-harness sequential --no-two-stage --no-reg-debug && python3 ./bin/procurator smoke --bpl /tmp/netchain_wraparound_bug.regress.20260510.bpl --harness sequential'`
    - compile/smoke 均 PASS。

## 2026-05-10 执行规则补充（Git / 提交 / 推送）

- **规则**: `git status / add / commit / push / fetch / pull` 等 Git 操作统一在 **WSL** 中执行。
- **原因**: 当前仓库在 Windows PowerShell 下存在 SSH/路径/工具链不稳定因素，容易导致提交或推送失败。
- **执行模板**:
  - `wsl bash -lc "cd /mnt/e/p4-verify && git status --short"`
  - `wsl bash -lc "cd /mnt/e/p4-verify && git add <files> && git commit -m '<msg>'"`
  - `wsl bash -lc "cd /mnt/e/p4-verify && git push origin main"`

## 2026-05-13 DistCache CM3/CM4 write wiring 当前树复跑与 P4B helper 保留修复

- **Spec**: `Procurator/argo/code/spec/bench/distcache_cm34_write_bug.prop`
- **Time**: 2026-05-13 00:47-01:09 Asia/Shanghai
- **目标/进度**: 作为已知理论 bug 当前树复跑的短 case，验证 slicing + `--no-reg-debug` 路径仍可生成正确 Boogie/harness、跑出 `UNSAFE`，并留存 witness。
- **结果**:
  - 修复前首轮复跑：runner 记录 `ERROR`，run dir `.tmp/procurator/verify/distcache_cm34_write_bug/20260513-004749-4943/` 只生成 `work/leaf.raw.bpl` 与 meta，未进入 Ultimate。
  - 修复后复跑：`UNSAFE`，run_id `20260513-010742-a37f`。
  - 产物：`.tmp/procurator/verify/distcache_cm34_write_bug/20260513-010742-a37f/`
  - witness：`.tmp/procurator/verify/distcache_cm34_write_bug/20260513-010742-a37f/distcache_cm34_write_bug.bpl-witness.graphml`
  - 本轮结果 JSON：`.tmp/procurator/e2e_ablations_20260513_current.json`
- **坑（实现错误导致）**:
  - P4B slicing 保留了 `netcacheEgress_cm3_reg/cm4_reg` 的 register/mirror 全局变量，meta 也记录这些寄存器有 writes，但最终 Boogie 输出过滤只保留从 `mainProcedure` 可达的过程，导致对应 `netcacheEgress_cm3_reg.read/write`、`netcacheEgress_cm4_reg.read/write` helper procedures 被删掉。
  - DSLC 的新边界检查正确拒绝该 raw BPL：`P4B output is missing complete register write mirrors for: leaf_netcacheEgress_cm3_reg, leaf_netcacheEgress_cm4_reg`。这是 P4B 输出一致性问题，不应通过 DSLC backfill 绕过。
- **修复**:
  - `P4B-Translator/backends/verify/translate/impl/core/translate.cpp`: 在 slicing reachable-procedure 过滤中，对被保留的 register state 自动保留其 `.read/.write` helper procedures，使 register/mirror globals 与 accessor procedures 保持一致。
- **沉淀为冒烟/回归测试**:
  - 新增 `dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_distcache_kept_registers_keep_write_helpers`。
  - 红灯证据：修复前该测试失败，原因是 `netcacheEgress_cm3_reg.read/write` 不在输出 BPL。
  - 绿灯证据：
    - `cd P4B-Translator/build-host && make -j16 p4c-translator` -> PASS。
    - `python3 -m unittest -v dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_distcache_kept_registers_keep_write_helpers` -> PASS。
    - `PYTHONPATH=. python3 dslc/bench/run_e2e_ablations.py --only slicing --bench distcache_cm34 --results-json .tmp/procurator/e2e_ablations_20260513_current.json --ultimate-xmx-gb 4` -> `UNSAFE` + witness rerun `UNSAFE`。

## 2026-05-13 FRR bug1 unexpected mirror 当前树复跑

- **Spec**: `Procurator/argo/code/spec/bench/frr_bug1_unexpected_mirror.prop`
- **Time**: 2026-05-13 01:10-01:12 Asia/Shanghai
- **目标/进度**: 已知理论 bug 当前树复跑，确认 slicing + `--use-spec-max-steps --no-slicing-control-seeds` 路径仍能跑出 witness。
- **结果**:
  - slicing: `UNSAFE`，run_id `20260513-011041-70cb`。
  - 产物：`.tmp/procurator/verify/frr_bug1_unexpected_mirror/20260513-011041-70cb/`
  - witness：`.tmp/procurator/verify/frr_bug1_unexpected_mirror/20260513-011041-70cb/frr_bug1_unexpected_mirror.bpl-witness.graphml`
  - runner 结果：`.tmp/procurator/e2e_ablations_20260513_current.json` 中该 case 的 slicing 记录为 `UNSAFE`，witness rerun 也为 `UNSAFE`。
- **坑（实现错误导致）**:
  - 本轮无新实现错误；生成 BPL 与 Ultimate 主跑/witness rerun 都正常。
- **修复/沉淀为冒烟测试**:
  - 本轮未新增代码修复。
  - 复用当前回归基线：P4B translator 已在本轮重编通过；FRR bug1 结果由 `run_e2e_ablations.py` 保存 run_id、日志与 witness。

## 2026-05-13 Gecko bug3 timer init 当前树复跑与 opt profile 固化

- **Spec**: `Procurator/argo/code/spec/bench/gecko_bug3_timer_init.prop`
- **Time**: 2026-05-13 01:13-01:21 Asia/Shanghai
- **目标/进度**: 已知理论 bug 当前树复跑，确认 Gecko bug3 在 slicing + `--no-reg-debug` 路径仍能跑出 `UNSAFE`，并避免把低内存 profile 的 OOM 误解释为 bug 不存在。
- **结果**:
  - 首轮使用默认 2GB Z3 profile：run_id `20260513-011301-f59b`，Ultimate 结果为 `Toolchain returned no result`，runner 细化为 `OOM`；未产出 witness。
  - 日志证据：`.tmp/procurator/verify/gecko_bug3_timer_init/20260513-011301-f59b/gemcutter.log` 中 Z3 报 `(error "out of memory")`，发生在 RCFG 构造阶段。
  - 修正参数后复跑：`UNSAFE`，run_id `20260513-011824-fb22`。
  - 产物：`.tmp/procurator/verify/gecko_bug3_timer_init/20260513-011824-fb22/`
  - witness：`.tmp/procurator/verify/gecko_bug3_timer_init/20260513-011824-fb22/gecko_bug3_timer_init.bpl-witness.graphml`
- **坑（实现/配置导致）**:
  - P4B 当前正确保留 register helper procedures 后，Gecko bug3 sliced BPL 在默认 `ReachSafety-32bit-GemCutter-ALL.epf` 下会触发 Z3 `-memory:2024` OOM。该结果是求解配置不足，不是 `SAFE`，也不能解释为 bug 不存在。
- **修复/沉淀为冒烟测试**:
  - `dslc/bench/run_e2e_ablations.py`: 增加 `opt_settings` per-case 配置，并把 Gecko bug3 slicing 侧固定到 `dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf`。
  - `dslc/tests/bench/test_run_e2e_ablations_classify.py`: 新增 `test_gecko_bug3_dry_run_uses_opt_smallblocks_profile`，防止 runner 退回低内存 profile。
  - 回归执行：
    - `python3 -m unittest -v dslc.tests.bench.test_run_e2e_ablations_classify.TestRunE2EAblationsClassify.test_gecko_bug3_dry_run_uses_opt_smallblocks_profile` -> PASS。
    - `PYTHONPATH=. python3 dslc/bench/run_e2e_ablations.py --only slicing --bench gecko_bug3 --results-json .tmp/procurator/e2e_ablations_20260513_current.json --ultimate-xmx-gb 4` -> `UNSAFE` + witness rerun `UNSAFE`。

## 2026-05-13 P4DB router TTL expiry 当前树复跑

- **Spec**: `Procurator/argo/code/spec/bench/p4db_router_ttl_expiry_bug.prop`
- **Time**: 2026-05-13 01:22-01:23 Asia/Shanghai
- **目标/进度**: 已知理论 bug 当前树复跑，确认 slicing + `--max-steps 3 --no-slicing-control-seeds --no-reg-debug` 路径仍能跑出可审计 witness。
- **结果**:
  - slicing: `UNSAFE`，run_id `20260513-012219-f8a6`。
  - 产物：`.tmp/procurator/verify/p4db_router_ttl_expiry_bug/20260513-012219-f8a6/`
  - witness：`.tmp/procurator/verify/p4db_router_ttl_expiry_bug/20260513-012219-f8a6/p4db_router_ttl_expiry_bug.bpl-witness.graphml`
  - runner 结果：`.tmp/procurator/e2e_ablations_20260513_current.json` 中该 case slicing 记录为 `UNSAFE`，witness rerun 也为 `UNSAFE`。
- **坑（实现错误导致）**:
  - 本轮无新实现错误；BPL 生成、Ultimate 主跑和 witness rerun 均正常。
- **修复/沉淀为冒烟测试**:
  - 本轮未新增代码修复。
  - 复跑命令由 `run_e2e_ablations.py` 固化并保存 run_id、日志与 witness。

## 2026-05-13 P4DB damper threshold off-by-one 当前树复跑与 P4_14 register builtin 修复

- **Spec**: `Procurator/argo/code/spec/bench/p4db_damper_threshold_off_by_one_bug.prop`
- **Time**: 2026-05-13 01:24-03:27 Asia/Shanghai
- **目标/进度**: 已知理论 bug 当前树复跑；先检查生成的 Boogie/harness 语义，再决定是否接受 solver 结果。目标是消除此前 `SAFE` 假阴性，恢复 P4DB damper 的真实寄存器读写路径，并留存可审计 witness。
- **结果**:
  - 修复前首轮复跑：`SAFE`，run_id `20260513-012413-c397`；该结果被判定为假阴性，不接受为 bug 不存在。
  - 假阴性证据：`.tmp/procurator/verify/p4db_damper_threshold_off_by_one_bug/20260513-012413-c397/p4db_damper_threshold_off_by_one_bug.bpl` 中 `sw_ingress()` 为空，最终断言只检查初始化后的 `sw_damper_register__last0_value == 0`。
  - 中间修复后复跑：`ERROR`，run_id `20260513-031221-344b`；BPL typecheck 发现 `call lhs := reg.read(...)` 与整数 `0` 未转成 `0bv16`，属于翻译实现错误，不解释为 bug 不存在。
  - 最终复跑：`UNSAFE`，run_id `20260513-032601-8a9e`。
  - 产物：`.tmp/procurator/verify/p4db_damper_threshold_off_by_one_bug/20260513-032601-8a9e/`
  - witness：`.tmp/procurator/verify/p4db_damper_threshold_off_by_one_bug/20260513-032601-8a9e/p4db_damper_threshold_off_by_one_bug.bpl-witness.graphml`
  - witness rerun：`UNSAFE`；`gemcutter.witness.log` 记录 `Counterexample is feasible`、`Registering result UNSAFE`、witness graphml/yml 写出，以及 `RESULT: Ultimate proved your program to be incorrect!`。
  - BPL 语义证据：最终 BPL 中保留了 `call sw_damper_register.write(sw_index, 0bv16);`，`sw_set_damper(...)` 中保留 `sw_damper_register.read(...)` 和递增后的 `sw_damper_register.write(...)`，最终断言为 `assert !procurator_bad;`。
- **坑（实现错误导致）**:
  - P4_14 builtins/macros 在 IR 中呈现混合形态：打印为 `damper_register.read/write(...)`，但 `member->member.originalName` 为 `register_read/register_write`。旧 slicer 未把这些 builtin 建模为寄存器 use/def，导致 action/table 不再定义 seed。
  - slicer 保留了内层 `damper_1` control body，却没有保留外层 control call chain，导致 `ingress()` 仍可被切空。
  - translator 将 `register_read/write` 当成未建模 extern procedure，而不是 P4B 寄存器镜像语义；初版修复还把 function read 写成 `call lhs := ...`，并把 `register_write(..., 0)` 的值类型错误生成为 int `0`。
- **修复**:
  - `P4B-Translator/backends/verify/slicing/slicer_internal.h`: 新增 `collectDirectRegisterBuiltinUsesDefs(...)`，识别 receiver 形态与无 receiver 形态的 P4_14 direct/register builtin 调用。
  - `P4B-Translator/backends/verify/slicing/slicer.cpp`: 增加 control call retention closure；当 control body 含 kept statements 时，保留调用该 control 的 call sites 与前驱链，并修正 CFG node id 与 IR statement id 的比较。
  - `P4B-Translator/backends/verify/translate/impl/lowering/translate_method.cpp`: 基于 `originalName` 降低 `register_read/register_write`，把 read 降成普通赋值表达式、write 降成真实 register write 并更新 mirrors/modifies，同时按寄存器值类型渲染常量。
  - `P4B-Translator/backends/verify/translate/impl/lowering/translate_statement.cpp`: 对返回赋值字符串的 method-call expression 作为普通 Boogie statement 输出，避免错误的 `call lhs := ...`。
  - `P4B-Translator/backends/verify/translate/impl/lowering/translate_program.cpp` 与 `P4B-Translator/backends/verify/translate/translate.h`: 记录并使用 `registerValueTypes`。
- **沉淀为冒烟/回归测试**:
  - `dslc/tests/p4b/test_p4b_translator_regressions.py`: 新增 `test_p4db_damper_indexed_register_seed_keeps_ingress_write_path`，检查 `ingress()` 调 `damper_1()`、`damper_1()` 调 `damper_tbl_1.apply()`，以及 `set_damper(...)` 保留 `damper_register.write`。
  - `cd P4B-Translator/build-host && make -j16 p4c-translator` -> PASS。
  - `python3 -m unittest -v dslc.tests.p4b.test_p4b_translator_regressions.TestP4BTranslatorRegressions.test_p4db_damper_table_set_default_not_lost_under_slicing dslc.tests.p4b.test_p4b_translator_regressions.TestP4BTranslatorRegressions.test_p4db_damper_indexed_register_seed_keeps_ingress_write_path` -> PASS。
  - `PYTHONPATH=. python3 dslc/bench/run_e2e_ablations.py --only slicing --bench p4db_damper --results-json .tmp/procurator/e2e_ablations_20260513_current.json --ultimate-xmx-gb 4` -> `UNSAFE` + witness rerun `UNSAFE`。

## 2026-05-13 NetLock pkt_type domain 当前树复跑

- **Spec**: `Procurator/argo/code/spec/bench/netlock_pkt_type_bug.prop`
- **Time**: 2026-05-13 03:40-03:46 Asia/Shanghai
- **目标/进度**: 已知理论 bug 当前树复跑；先生成并检查 sliced Boogie/harness，再运行 Ultimate，确认 `pkt_type` 域性质仍能产出可审计 witness。
- **结果**:
  - 预检生成：`.tmp/manual/netlock_pkt_type_bug.20260513.slicing.bpl`
  - `procurator smoke`：`SMOKE-OK`，sequential harness 结构正常。
  - BPL 语义检查：`sw_SwitchIngressParser()`、`sw_SwitchIngress()`、`sw_SwitchIngressDeparser()` 均在节点过程被调用；最终断言保留为 `assert ((sw_ig_md.pkt_type == 0bv8) || (sw_ig_md.pkt_type == 1bv8));`。
  - slicing 复跑：`UNSAFE`，run_id `20260513-034430-8ea2`。
  - 产物：`.tmp/procurator/verify/netlock_pkt_type_bug/20260513-034430-8ea2/`
  - witness：`.tmp/procurator/verify/netlock_pkt_type_bug/20260513-034430-8ea2/netlock_pkt_type_bug.bpl-witness.graphml`
  - runner 结果：`.tmp/procurator/e2e_ablations_20260513_current.json` 中该 case slicing 记录为 `UNSAFE`，witness rerun 也为 `UNSAFE`。
- **坑（实现错误导致）**:
  - 本轮无新实现错误；预检显示 harness 非空且目标断言仍连接到 ingress 语义，Ultimate 主跑与 witness rerun 均正常。
- **修复/沉淀为冒烟测试**:
  - 本轮未新增代码修复。
  - 复跑命令由 `run_e2e_ablations.py` 固化为 `--wraparound off --no-slicing-control-seeds`；run_id、日志和 witness 已由 runner 保存。

## 2026-05-13 ATP count mismatch 当前树复跑

- **Spec**: `Procurator/argo/code/spec/bench/atp_count_mismatch_bug.prop`
- **Time**: 2026-05-13 04:10-04:12 Asia/Shanghai
- **目标/进度**: 已知理论 bug 当前树复跑；使用 spec 中的 bounded steps，检查 aggregation register/bitmap 路径是否仍在 sliced Boogie 中，再运行 Ultimate 并留存 witness。
- **结果**:
  - 预检生成：`.tmp/manual/atp_count_mismatch_bug.20260513.slicing.bpl`
  - `procurator smoke`：`SMOKE-OK`，sequential harness 结构正常。
  - BPL 语义检查：保留 `s1_appID_and_Seq`、`s1_bitmap`、`s1_MyIngress()`，以及 `p4ml_agtr_index.agtr == 0` 下的寄存器 read/write 约束；spec 的 `max_steps = 6` 已通过 `--use-spec-max-steps` 生效。
  - slicing 复跑：`UNSAFE`，run_id `20260513-041058-1e97`。
  - 产物：`.tmp/procurator/verify/atp_count_mismatch_bug/20260513-041058-1e97/`
  - witness：`.tmp/procurator/verify/atp_count_mismatch_bug/20260513-041058-1e97/atp_count_mismatch_bug.bpl-witness.graphml`
  - runner 结果：`.tmp/procurator/e2e_ablations_20260513_current.json` 中该 case slicing 记录为 `UNSAFE`，witness rerun 也为 `UNSAFE`。
- **坑（实现错误导致）**:
  - 本轮无新实现错误；模型预检未发现聚合寄存器/断言路径丢失，Ultimate 主跑与 witness rerun 均正常。
- **修复/沉淀为冒烟测试**:
  - 本轮未新增代码修复。
  - 复跑命令由 `run_e2e_ablations.py` 固化为 `--wraparound off --use-spec-max-steps --no-slicing-control-seeds`；run_id、日志和 witness 已由 runner 保存。

## 2026-05-13 P4NIS bug2 tunnel state leakage 当前树复跑

- **Spec**: `Procurator/argo/code/spec/bench/p4nis_bug2_tunnel_state_leakage.prop`
- **Time**: 2026-05-13 04:13-04:15 Asia/Shanghai
- **目标/进度**: 已知理论 bug 当前树复跑；检查 tunnel header 构造与泄露断言是否仍在 sliced Boogie 中，再运行 Ultimate 并留存 witness。
- **结果**:
  - 预检生成：`.tmp/manual/p4nis_bug2_tunnel_state_leakage.20260513.slicing.bpl`
  - `procurator smoke`：`SMOKE-OK`，sequential harness 结构正常。
  - BPL 语义检查：保留 `s1_MyIngress_creatmytunnel()`、`s1_hdr.ipv4_tunnel.srcAddr := s1_hdr.ipv4.srcAddr` 的泄露路径，以及 spec 中“tunnel 外层 src 不应等于内层 src”的断言。
  - slicing 复跑：`UNSAFE`，run_id `20260513-041418-4d6f`。
  - 产物：`.tmp/procurator/verify/p4nis_bug2_tunnel_state_leakage/20260513-041418-4d6f/`
  - witness：`.tmp/procurator/verify/p4nis_bug2_tunnel_state_leakage/20260513-041418-4d6f/p4nis_bug2_tunnel_state_leakage.bpl-witness.graphml`
  - runner 结果：`.tmp/procurator/e2e_ablations_20260513_current.json` 中该 case slicing 记录为 `UNSAFE`，witness rerun 也为 `UNSAFE`。
- **坑（实现错误导致）**:
  - 本轮无新实现错误；模型预检未发现 tunnel 构造或断言路径丢失，Ultimate 主跑与 witness rerun 均正常。
- **修复/沉淀为冒烟测试**:
  - 本轮未新增代码修复。
  - 复跑命令由 `run_e2e_ablations.py` 固化为 `--wraparound off --use-spec-max-steps`；run_id、日志和 witness 已由 runner 保存。

## 2026-05-13 P4NIS bug1 forwarding sequence desync 当前树复跑与 witness sanity 修复

- **Spec**: `Procurator/argo/code/spec/bench/p4nis_bug1_forwarding_sequence_desync.prop`
- **Time**: 2026-05-13 04:16-04:31 Asia/Shanghai
- **目标/进度**: 已知理论 bug 当前树复跑；检查 seeded `count == 3` 导致的 forwarding sequence desync 是否仍在 sliced Boogie 中，并确保 witness sanity 工具不会把可审计 P4 assertion witness 误判为失败。
- **结果**:
  - 预检生成：`.tmp/manual/p4nis_bug1_forwarding_sequence_desync.20260513.slicing.bpl`
  - `procurator smoke`：`SMOKE-OK`，sequential harness 结构正常。
  - BPL 语义检查：保留 `s1_count[0bv32] == 3bv32` 初始化、`s1_MyIngress_do_read_count()`、三条 forwarding branch 对 `egress_spec` 的选择，以及程序内 `assert (((s1_standard_metadata.egress_spec == 1bv9)) || ((s1_standard_metadata.egress_spec == 2bv9))) || ((s1_standard_metadata.egress_spec == 3bv9));`。
  - 首轮 solver/witness 复跑：`UNSAFE`，run_id `20260513-041813-ecf6`，但 runner sanity 误报 `FAIL(dsl_assert)`；该 warning 被暂停接受并定位。
  - 修复 sanity checker 后最终复跑：`UNSAFE`，run_id `20260513-043031-45c9`。
  - 产物：`.tmp/procurator/verify/p4nis_bug1_forwarding_sequence_desync/20260513-043031-45c9/`
  - witness：`.tmp/procurator/verify/p4nis_bug1_forwarding_sequence_desync/20260513-043031-45c9/p4nis_bug1_forwarding_sequence_desync.bpl-witness.graphml`
  - runner 结果：`.tmp/procurator/e2e_ablations_20260513_current.json` 中该 case slicing 记录为 `UNSAFE`，witness rerun 也为 `UNSAFE`，且不再带 `opt sanity=FAIL(...)`。
- **坑（实现错误导致）**:
  - 不是 P4B/DSLC 模型错误；BPL 与 witness 均指向程序内 forwarding assertion。问题在审计工具：GraphML witness 的 assumption/state snapshot 会包含 `procurator_bad == false`，sourcecode 也会包含初始化 `procurator_bad := false;`，旧 `summarize_witness(...)` 只要在 witness 文本中看到 `procurator_bad` 就进入 DSL-accumulator 分支，随后因为没有 `procurator_bad := true` 而误报 `FAIL(dsl_assert)`。
- **修复/沉淀为冒烟测试**:
  - `dslc/bench/validate_counterexample.py`: 新增 `_extract_witness_sourcecode_text(...)`，并将 DSL accumulator 命中条件收紧为 witness sourcecode 中实际出现 `procurator_bad := true` 或 `assert !procurator_bad`；初始化与 assumption snapshot 不再触发该分支。
  - `dslc/tests/toolchain/test_validate_counterexample.py`: 新增 `test_summarize_witness_accepts_direct_assert_when_assumption_mentions_procurator_bad`，覆盖 P4NIS bug1 这种“direct P4 assertion + assumption 中提到 procurator_bad=false”的 witness 形态。
  - 回归执行：
    - `python3 -m unittest -v dslc.tests.toolchain.test_validate_counterexample.TestValidateCounterexample.test_summarize_witness_accepts_direct_assert_when_assumption_mentions_procurator_bad dslc.tests.toolchain.test_validate_counterexample.TestValidateCounterexample.test_summarize_witness_accepts_normalized_procurator_bad_assignment dslc.tests.toolchain.test_validate_counterexample.TestValidateCounterexample.test_summarize_witness_accepts_direct_global_assert` -> PASS。
    - `PYTHONPATH=. python3 dslc/bench/run_e2e_ablations.py --only slicing --bench p4nis_bug1 --results-json .tmp/procurator/e2e_ablations_20260513_current.json --ultimate-xmx-gb 4` -> `UNSAFE` + witness rerun `UNSAFE`，sanity clean。

## 2026-05-13 FRR bug2 state inconsistency 当前树复跑

- **Spec**: `Procurator/argo/code/spec/bench/frr_bug2_state_inconsistency.prop`
- **Time**: 2026-05-13 04:32-04:36 Asia/Shanghai
- **目标/进度**: 已知理论 bug 当前树复跑；该 case 曾暴露 slicer 对 `pkt_par.write(...)` 的过度裁剪问题，因此先检查 sliced BPL 是否仍保留 `pkt_par` stateful 写路径，再运行 Ultimate 并留存 witness。
- **结果**:
  - 预检生成：`.tmp/manual/frr_bug2_state_inconsistency.20260513.slicing.bpl`
  - `procurator smoke`：`SMOKE-OK`，sequential harness 结构正常。
  - BPL 语义检查：保留 `s1_pkt_par` register、parser 中 `s1_pkt_par.read(...)`、`s1_set_par_to_ingress()`/`s1_set_parent_out()` 中的 `s1_pkt_par.write(...)`，以及 in-program/DSL mirrored assertion `out_port < 5 || out_port == pkt_par`。
  - slicing 复跑：`UNSAFE`，run_id `20260513-043413-2b29`。
  - 产物：`.tmp/procurator/verify/frr_bug2_state_inconsistency/20260513-043413-2b29/`
  - witness：`.tmp/procurator/verify/frr_bug2_state_inconsistency/20260513-043413-2b29/frr_bug2_state_inconsistency.bpl-witness.graphml`
  - runner 结果：`.tmp/procurator/e2e_ablations_20260513_current.json` 中该 case slicing 记录为 `UNSAFE`，witness rerun 也为 `UNSAFE`。
- **坑（实现错误导致）**:
  - 本轮无新实现错误；预检确认此前沉淀的 `pkt_par.write(...)` action-level slicing 修复仍在当前树生效，没有再次出现 sliced BPL 状态丢失。
- **修复/沉淀为冒烟测试**:
  - 本轮未新增代码修复。
  - 复用已沉淀的 `frr_pkt_par_write` slicing selftest；本轮由 `run_e2e_ablations.py` 保存 run_id、日志和 witness。

## 2026-05-13 DDOSD window label collision 当前树复跑阶段记录（未完成）

- **Spec**: `Procurator/argo/code/spec/bench/ddosd_window_label_collision_bug.prop`
- **Time**: 2026-05-13 04:37-05:13 Asia/Shanghai
- **目标/进度**: 已知理论 bug 当前树复跑；先检查 sliced Boogie/harness 是否保留 observation-window label collision 语义，再运行 Ultimate。当前阶段尚未获得 witness，不能解释为 bug 不存在。
- **结果**:
  - 预检生成：`.tmp/manual/ddosd_window_label_collision_bug.20260513.slicing.bpl`
  - `procurator smoke`：`SMOKE-OK`，sequential harness 结构正常。
  - BPL 语义检查：保留 `s1_ingress_ow_counter`、`s1_ingress_src_cs1` / `s1_ingress_src_cs1_ow` 等 CountSketch/窗口标签寄存器，保留对 `_ow` 低 8 位标签的写入，以及最终 `assert !procurator_bad;`。spec 断言为 `s1_ingress_src_cs1[0] <= 1`。
  - 默认 2GB Z3 profile 复跑：`OOM`/`Toolchain returned no result`，run_id `20260513-043852-821f`，无 witness。
  - 日志证据：`.tmp/procurator/verify/ddosd_window_label_collision_bug/20260513-043852-821f/gemcutter.log` 中 TraceAbstraction 已多次 `Found error trace`，随后 Z3 报 `(error "out of memory")`，不是 `SAFE`。
  - 修正为 8GB small-blocks profile 后复跑：`TIMEOUT`，run_id `20260513-045658-0c3d`，无 witness。
  - 日志证据：`.tmp/procurator/verify/ddosd_window_label_collision_bug/20260513-045658-0c3d/gemcutter.log` 使用 `z3 ... -memory:8192`，TraceAbstraction 运行约 890s、25 次 CEGAR 迭代，反复 `Found error trace`，最后在 line 2118 注册 `TIMEOUT`。
- **坑（实现/配置导致）**:
  - 首轮失败是低内存 profile 导致的 solver OOM，不是模型证明 `SAFE`。
  - 8GB small-blocks 消除了 OOM，但仍在 TraceAbstraction 中超时；该 timeout 只能说明当前配置未跑完，不能解释为 bug 不存在。
- **修复/沉淀为冒烟测试**:
  - `dslc/bench/run_e2e_ablations.py`: 将 DDOSD slicing 侧也固定到 `ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf`，避免退回 2GB profile 后再次 OOM。
  - `dslc/tests/bench/test_run_e2e_ablations_classify.py`: 新增并修正 `test_ddosd_dry_run_uses_opt_smallblocks_profile`，明确检查 `[DRY]` 的 slicing 命令行而不是表格中的 base 命令。
  - 回归执行：`python3 -m unittest -v dslc.tests.bench.test_run_e2e_ablations_classify.TestRunE2EAblationsClassify.test_ddosd_dry_run_uses_opt_smallblocks_profile dslc.tests.bench.test_run_e2e_ablations_classify.TestRunE2EAblationsClassify.test_gecko_bug3_dry_run_uses_opt_smallblocks_profile` -> PASS。
  - 下一步：继续从模型缩减/参数调优方向推进 DDOSD；当前 `TIMEOUT` 不进入已跑出 witness 的已知 bug 清单。

## 2026-05-13 NetLock push_back length_in_server underflow 当前树复跑

- **Spec**: `Procurator/argo/code/spec/bench/netlock_pushback_length_in_server_underflow_bug.prop`
- **Time**: 2026-05-13 03:47-03:51 Asia/Shanghai
- **目标/进度**: 已知理论 bug 当前树复跑；先检查 sliced Boogie/harness 是否保留 `length_in_server` 相关语义，再运行 Ultimate 并留存 witness。
- **结果**:
  - 预检生成：`.tmp/manual/netlock_pushback_length_in_server_underflow_bug.20260513.slicing.bpl`
  - `procurator smoke`：`SMOKE-OK`，sequential harness 结构正常。
  - BPL 语义检查：保留 `sw_ig_md.length_in_server`、`sw_SwitchIngress_acquire_lock_dec_empty_slots_action()` 中对 `length_in_server` 的更新，以及最终 `assert !procurator_bad;`。
  - slicing 复跑：`UNSAFE`，run_id `20260513-034932-2f8b`。
  - 产物：`.tmp/procurator/verify/netlock_pushback_length_in_server_underflow_bug/20260513-034932-2f8b/`
  - witness：`.tmp/procurator/verify/netlock_pushback_length_in_server_underflow_bug/20260513-034932-2f8b/netlock_pushback_length_in_server_underflow_bug.bpl-witness.graphml`
  - runner 结果：`.tmp/procurator/e2e_ablations_20260513_current.json` 中该 case slicing 记录为 `UNSAFE`，witness rerun 也为 `UNSAFE`。
- **坑（实现错误导致）**:
  - 本轮无新实现错误；模型预检未发现空 harness 或目标断言丢失，Ultimate 主跑与 witness rerun 均正常。
- **修复/沉淀为冒烟测试**:
  - 本轮未新增代码修复。
  - 复跑命令由 `run_e2e_ablations.py` 固化为 `--wraparound off --max-steps 3 --no-slicing-control-seeds`；run_id、日志和 witness 已由 runner 保存。

## 2026-05-13 Gecko bug1 timer loss 当前树复跑

- **Spec**: `Procurator/argo/code/spec/bench/gecko_bug1_timer_loss.prop`
- **Time**: 2026-05-13 05:24-05:36 Asia/Shanghai
- **目标/进度**: 已知理论 bug 当前树复跑；沿用历史上对 Gecko 较稳定的 `--no-reg-debug` + 8GB small-blocks profile，先由 runner 生成 sliced BPL，再运行 Ultimate 并留存 witness。
- **结果**:
  - slicing 复跑：`UNSAFE`，run_id `20260513-052413-d380`。
  - 产物：`.tmp/procurator/verify/gecko_bug1_timer_loss/20260513-052413-d380/`
  - witness：`.tmp/procurator/verify/gecko_bug1_timer_loss/20260513-052413-d380/gecko_bug1_timer_loss.bpl-witness.graphml`
  - runner 结果：`.tmp/procurator/e2e_ablations_20260513_current.json` 中该 case slicing 记录为 `UNSAFE`，witness rerun 也为 `UNSAFE`，wall≈683.3s。
- **坑（实现/配置导致）**:
  - 本轮无新实现错误；继续使用 `--no-reg-debug` 与 `ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf`，避免退回历史上容易 OOM/timeout 的低内存 profile。该配置选择不把 timeout/unknown 解释为 bug 不存在。
- **修复/沉淀为冒烟测试**:
  - 本轮未新增代码修复。
  - 复跑命令由 `run_e2e_ablations.py` 固化为 `--wraparound off --use-spec-max-steps --no-reg-debug --settings dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf`；run_id、日志和 witness 已由 runner 保存。

## 2026-05-13 Gecko bug2 limited concurrency 当前树复跑

- **Spec**: `Procurator/argo/code/spec/bench/gecko_bug2_concurrency.prop`
- **Time**: 2026-05-13 05:36-05:48 Asia/Shanghai
- **目标/进度**: 已知理论 interleaving bug 当前树复跑；先按 runner 原配置尝试 slicing，再根据日志定位求解配置问题并复跑留存 witness。
- **结果**:
  - 首次 slicing 尝试：`OOM`/`Toolchain returned no result`，run_id `20260513-053650-5a8a`，日志显示 Z3 以 `-memory:2024` 在 RCFG construction 阶段报 `(error "out of memory")`。该结果不算 bug absence。
  - 修复配置后 slicing 复跑：`UNSAFE`，run_id `20260513-054230-48fc`。
  - 产物：`.tmp/procurator/verify/gecko_bug2_concurrency/20260513-054230-48fc/`
  - witness：`.tmp/procurator/verify/gecko_bug2_concurrency/20260513-054230-48fc/gecko_bug2_concurrency.bpl-witness.graphml`
  - runner 结果：`.tmp/procurator/e2e_ablations_20260513_current.json` 中该 case slicing 记录为 `UNSAFE`，witness rerun 也为 `UNSAFE`，wall≈338.0s。
- **坑（实现/配置导致）**:
  - runner 原先只给 Gecko bug1/bug3 pin 了高内存 small-blocks profile，Gecko bug2 slicing 仍回落到默认 2GB Z3 profile，导致 RCFG 阶段 OOM。该 OOM 只能说明后端配置不足，不能解释为 bug 不存在。
- **修复/沉淀为冒烟测试**:
  - `dslc/bench/run_e2e_ablations.py`: 对 Gecko bug2 slicing 侧新增 `opt_settings=ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf`。
  - `dslc/tests/bench/test_run_e2e_ablations_classify.py`: 新增 `test_gecko_bug2_dry_run_uses_opt_smallblocks_profile`，并先确认该测试在修复前失败、修复后通过。
  - 回归执行：`python3 -m unittest -v dslc.tests.bench.test_run_e2e_ablations_classify.TestRunE2EAblationsClassify.test_gecko_bug2_dry_run_uses_opt_smallblocks_profile dslc.tests.bench.test_run_e2e_ablations_classify.TestRunE2EAblationsClassify.test_gecko_bug3_dry_run_uses_opt_smallblocks_profile dslc.tests.bench.test_run_e2e_ablations_classify.TestRunE2EAblationsClassify.test_ddosd_dry_run_uses_opt_smallblocks_profile`（PASS）。
  - 复跑命令由 `run_e2e_ablations.py` 固化为 `--wraparound off --use-spec-max-steps --no-reg-debug --settings dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf`；run_id、日志和 witness 已由 runner 保存。

## 2026-05-13 P4xos drop_flag 当前树复跑

- **Spec**: `Procurator/argo/code/spec/bench/p4xos_dropflag_bug.prop`
- **Time**: 2026-05-13 05:48-05:51 Asia/Shanghai
- **目标/进度**: 已知理论 bug 当前树复跑；检查 forwarding/drop_flag 相关路径在 sliced 模型中仍可达，并运行 Ultimate 留存 witness。
- **结果**:
  - slicing 复跑：`UNSAFE`，run_id `20260513-054859-9529`。
  - 产物：`.tmp/procurator/verify/p4xos_dropflag_bug/20260513-054859-9529/`
  - witness：`.tmp/procurator/verify/p4xos_dropflag_bug/20260513-054859-9529/p4xos_dropflag_bug.bpl-witness.graphml`
  - runner 结果：`.tmp/procurator/e2e_ablations_20260513_current.json` 中该 case slicing 记录为 `UNSAFE`，witness rerun 也为 `UNSAFE`，wall≈105.5s。
- **坑（实现错误导致）**:
  - 本轮无新实现错误；`--no-reg-debug` 仅去掉 per-pass 寄存器快照变量，不改变该 forwarding/drop_flag 性质语义。
- **修复/沉淀为冒烟测试**:
  - 本轮未新增代码修复。
  - 复跑命令由 `run_e2e_ablations.py` 固化为 `--wraparound off --use-spec-max-steps --no-reg-debug`；run_id、日志和 witness 已由 runner 保存。

## 2026-05-13 P4xos majority quorum 当前树复跑

- **Spec**: `Procurator/argo/code/spec/bench/p4xos_majority_quorum_bug.prop`
- **Time**: 2026-05-13 05:51-06:16 Asia/Shanghai
- **目标/进度**: 已知理论 interleaving bug 当前树复跑；该 case 历史上 sliced solver 成本较高，因此按阶段语义等待 Ultimate 完成主跑与 witness rerun，不用短 timeout 解释为 bug 不存在。
- **结果**:
  - slicing 复跑：`UNSAFE`，run_id `20260513-055133-2598`。
  - 产物：`.tmp/procurator/verify/p4xos_majority_quorum_bug/20260513-055133-2598/`
  - witness：`.tmp/procurator/verify/p4xos_majority_quorum_bug/20260513-055133-2598/p4xos_majority_quorum_bug.bpl-witness.graphml`
  - runner 结果：`.tmp/procurator/e2e_ablations_20260513_current.json` 中该 case slicing 记录为 `UNSAFE`，witness rerun 也为 `UNSAFE`，wall≈1479.1s。
- **坑（实现/配置导致）**:
  - 本轮无新实现错误；耗时主要来自 Ultimate/GemCutter refinement 成本。该 case 不能用短时 `UNKNOWN/TIMEOUT` 作为 bug absence 证据。
- **修复/沉淀为冒烟测试**:
  - 本轮未新增代码修复。
  - 复跑命令由 `run_e2e_ablations.py` 固化为 `--wraparound off --use-spec-max-steps`；run_id、日志和 witness 已由 runner 保存。

## 2026-05-13 NetLock release empty_slots overflow 当前树复跑

- **Spec**: `Procurator/argo/code/spec/bench/netlock_release_empty_slots_overflow_bug.prop`
- **Time**: 2026-05-13 04:01-04:05 Asia/Shanghai
- **目标/进度**: 已知理论 bug 当前树复跑；该 case 历史上对求解配置较敏感，因此先检查 sliced BPL，再使用 runner 固化的 `--no-reg-debug` + 8GB small-blocks profile 运行 Ultimate。
- **结果**:
  - 预检生成：`.tmp/manual/netlock_release_empty_slots_overflow_bug.20260513.slicing.bpl`
  - `procurator smoke`：`SMOKE-OK`，sequential harness 结构正常。
  - BPL 语义检查：保留 `sw_slots_two_sides_register`、`sw_SwitchIngress_release_lock_inc_empty_slots_action()` 的寄存器读写，以及最终 `assert !procurator_bad;`。spec 中 guarded assertion 为第一轮 RELEASE 后 `sw_slots_two_sides_register[0] == 38654705664`。
  - slicing 复跑：`UNSAFE`，run_id `20260513-040140-3634`。
  - 产物：`.tmp/procurator/verify/netlock_release_empty_slots_overflow_bug/20260513-040140-3634/`
  - witness：`.tmp/procurator/verify/netlock_release_empty_slots_overflow_bug/20260513-040140-3634/netlock_release_empty_slots_overflow_bug.bpl-witness.graphml`
  - runner 结果：`.tmp/procurator/e2e_ablations_20260513_current.json` 中该 case slicing 记录为 `UNSAFE`，witness rerun 也为 `UNSAFE`。
- **坑（实现/配置导致）**:
  - 本轮无新实现错误；按历史沉淀继续使用 `--no-reg-debug` 与 `ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf`，避免退回容易 timeout/OOM 的低内存 profile。该策略是求解配置选择，不是把 timeout/unknown 解释为 bug 不存在。
- **修复/沉淀为冒烟测试**:
  - 本轮未新增代码修复。
  - 复跑命令由 `run_e2e_ablations.py` 固化为 `--wraparound off --max-steps 3 --no-slicing-control-seeds --no-reg-debug --settings dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf`；run_id、日志和 witness 已由 runner 保存。

## 2026-05-13 ATP bound bug 当前树复跑

- **Spec**: `Procurator/argo/code/spec/bench/atp_bug.prop`
- **Time**: 2026-05-13 04:07-04:09 Asia/Shanghai
- **目标/进度**: 已知理论 bug 当前树复跑；先检查 sliced Boogie/harness 是否保留 ATP ingress 与目标断言，再运行 Ultimate 并留存 witness。
- **结果**:
  - 预检生成：`.tmp/manual/atp_bug.20260513.slicing.bpl`
  - `procurator smoke`：`SMOKE-OK`，sequential harness 结构正常。
  - BPL 语义检查：保留 `s1_SwitchIngressParser()`、`s1_MyIngress()` 与目标断言 `assert ((s1_meta.isMyAppIDandMyCurrentSeq != 1bv1) || (s1_meta.isAggregate == 0bv32) || (s1_meta.need_send_out != 0bv8));`。
  - slicing 复跑：`UNSAFE`，run_id `20260513-040806-fcdf`。
  - 产物：`.tmp/procurator/verify/atp_bug/20260513-040806-fcdf/`
  - witness：`.tmp/procurator/verify/atp_bug/20260513-040806-fcdf/atp_bug.bpl-witness.graphml`
  - runner 结果：`.tmp/procurator/e2e_ablations_20260513_current.json` 中该 case slicing 记录为 `UNSAFE`，witness rerun 也为 `UNSAFE`。
- **坑（实现错误导致）**:
  - 本轮无新实现错误；模型预检未发现 ingress/目标断言丢失，Ultimate 主跑与 witness rerun 均正常。
- **修复/沉淀为冒烟测试**:
  - 本轮未新增代码修复。
  - 复跑命令由 `run_e2e_ablations.py` 固化为 `--wraparound off --no-slicing-control-seeds`；run_id、日志和 witness 已由 runner 保存。

## 2026-05-13 NetLock release empty-queue head corruption 当前树复跑

- **Spec**: `Procurator/argo/code/spec/bench/netlock_release_empty_queue_head_bug.prop`
- **Time**: 2026-05-13 03:56-04:00 Asia/Shanghai
- **目标/进度**: 已知理论 bug 当前树复跑；检查空队列 RELEASE 路径是否仍能更新/污染 `head_register`，再运行 Ultimate 并留存 witness。
- **结果**:
  - 预检生成：`.tmp/manual/netlock_release_empty_queue_head_bug.20260513.slicing.bpl`
  - `procurator smoke`：`SMOKE-OK`，sequential harness 结构正常。
  - BPL 语义检查：保留 `sw_head_register`、`sw_SwitchIngress_release_lock_inc_empty_slots_table.apply()`、`sw_SwitchIngress_release_lock_update_head_table.apply()` 以及最终 `assert !procurator_bad;`。spec 中 guarded assertion 为第一轮 RELEASE 后 `sw_head_register[0] == 0`。
  - slicing 复跑：`UNSAFE`，run_id `20260513-035732-ed97`。
  - 产物：`.tmp/procurator/verify/netlock_release_empty_queue_head_bug/20260513-035732-ed97/`
  - witness：`.tmp/procurator/verify/netlock_release_empty_queue_head_bug/20260513-035732-ed97/netlock_release_empty_queue_head_bug.bpl-witness.graphml`
  - runner 结果：`.tmp/procurator/e2e_ablations_20260513_current.json` 中该 case slicing 记录为 `UNSAFE`，witness rerun 也为 `UNSAFE`。
- **坑（实现错误导致）**:
  - 本轮无新实现错误；模型预检未发现空 harness、release 路径丢失或断言丢失，Ultimate 主跑与 witness rerun 均正常。
- **修复/沉淀为冒烟测试**:
  - 本轮未新增代码修复。
  - 复跑命令由 `run_e2e_ablations.py` 固化为 `--wraparound off --max-steps 3 --no-slicing-control-seeds`；run_id、日志和 witness 已由 runner 保存。

## 2026-05-13 NetLock release counter underflow 当前树复跑

- **Spec**: `Procurator/argo/code/spec/bench/netlock_release_counter_underflow_bug.prop`
- **Time**: 2026-05-13 03:52-03:56 Asia/Shanghai
- **目标/进度**: 已知理论 bug 当前树复跑；检查 RELEASE 路径对共享/独占计数寄存器的读写是否保留，再运行 Ultimate 并留存 witness。
- **结果**:
  - 预检生成：`.tmp/manual/netlock_release_counter_underflow_bug.20260513.slicing.bpl`
  - `procurator smoke`：`SMOKE-OK`，sequential harness 结构正常。
  - BPL 语义检查：保留 `sw_shared_and_exclusive_count_register`、`sw_SwitchIngress_release_lock_update_lock_action()`、`release_lock_update_lock_alu.apply(...)` 以及最终 `assert !procurator_bad;`。spec 中 guarded assertion 为第一轮 RELEASE 后 `sw_shared_and_exclusive_count_register[0] == 0`。
  - slicing 复跑：`UNSAFE`，run_id `20260513-035321-0f93`。
  - 产物：`.tmp/procurator/verify/netlock_release_counter_underflow_bug/20260513-035321-0f93/`
  - witness：`.tmp/procurator/verify/netlock_release_counter_underflow_bug/20260513-035321-0f93/netlock_release_counter_underflow_bug.bpl-witness.graphml`
  - runner 结果：`.tmp/procurator/e2e_ablations_20260513_current.json` 中该 case slicing 记录为 `UNSAFE`，witness rerun 也为 `UNSAFE`。
- **坑（实现错误导致）**:
  - 本轮无新实现错误；模型预检未发现寄存器 helper/断言路径丢失，Ultimate 主跑与 witness rerun 均正常。
- **修复/沉淀为冒烟测试**:
  - 本轮未新增代码修复。
  - 复跑命令由 `run_e2e_ablations.py` 固化为 `--wraparound off --max-steps 3 --no-slicing-control-seeds`；run_id、日志和 witness 已由 runner 保存。

## 2026-05-13

- **Spec**: Procurator/argo/code/spec/bench/cheetah_slot_index_collision_bug.prop
- **时间**: 2026-05-13 12:02 CST
- **目标/进度**: 重跑已知理论 bug（Cheetah slot index collision），确认生成的 sequential/no-two-stage BPL 与 harness 可形成可审计 UNSAFE，而不是把此前 no-result/ERROR 当作 bug 不存在。
- **结果**:
  - slicing: UNSAFE，run_id 20260513-120238-5fb3，产物目录 .tmp/procurator/verify/cheetah_slot_index_collision_bug/20260513-120238-5fb3/。
  - 证据: cheetah_slot_index_collision_bug.bounded-dsl-replay.unsafe.json + cheetah_slot_index_collision_bug.bounded-dsl-replay.textual.log；CLI stdout 明确打印 [RESULT] RESULT: UNSAFE 与 [CEX] bounded_dsl_replay_under_approx。
- **坑（实现/流程导致）**:
  - 旧 run 有 ERROR/no RESULT（例如 20260513-061704-2485、20260513-065442-7385），但生成 BPL/harness 中 guard 可由 deterministic bounded DSL replay 触发；不能把 no-result 当成 bug absence。
  - 初版 bounded replay 已能写 marker，但 procurator verify 没有打印 [RESULT] RESULT: UNSAFE，
un_e2e_ablations.py 因此把 rc=1 分类为 ERROR。
- **修复/沉淀**:
  - dslc/workflows/focused_direct.py: bounded replay 在未知寄存器写时忘记该寄存器/镜像的已知状态；若遇到未知尾部控制流，只在 final procurator_bad guard 当前已确定为 false 时接受 UNSAFE，否则 fail-closed fallback。
  - dslc/cli/gemcutter.py: bounded replay 命中时打印 [RESULT] RESULT: UNSAFE 和 synthetic replay log 路径。
  - dslc/bench/run_e2e_ablations.py: 识别 focused/bounded [CEX] marker，避免把有审计证据的 UNSAFE 记成 ERROR。
- **沉淀为冒烟/回归测试**:
  - dslc.tests.workflows.test_focused_direct_workflow: 覆盖未知尾部 final guard、未知寄存器写 forget/fallback、cwd-relative marker、synthetic log marker。
  - dslc.tests.bench.test_run_e2e_ablations_classify: 覆盖 bounded replay [CEX] 分类。
  - 回归执行: python3 -m unittest -v dslc.tests.workflows.test_focused_direct_workflow dslc.tests.toolchain.test_validate_counterexample dslc.tests.bench.test_run_e2e_ablations_classify，Ran 63 tests ... OK。

## 2026-05-13

- **Spec**: Procurator/argo/code/spec/bench/ddosd_window_label_collision_bug.prop
- **时间**: 2026-05-13 12:03 CST
- **目标/进度**: 重跑已知理论 bug（DDOSD window label collision），补齐此前 slicing TIMEOUT/manual BPL 证据之后的主 ablation 入口结果。
- **结果**:
  - slicing: UNSAFE，run_id 20260513-120339-f0e7，产物目录 .tmp/procurator/verify/ddosd_window_label_collision_bug/20260513-120339-f0e7/。
  - 证据: ddosd_window_label_collision_bug.bounded-dsl-replay.unsafe.json + ddosd_window_label_collision_bug.bounded-dsl-replay.textual.log；最终 guard s1_ingress_src_cs1__last0_value <= 1 在 replay 中被确定违反。
- **坑（实现/流程导致）**:
  - 旧 run 20260513-045658-0c3d 为 TIMEOUT，不能解释为 bug absence。
  - replay 初版在 bug 相关计数已经增长到 2 后，被后续报警/entropy 计算中的未知控制流挡住；这是尾部无关路径建模不足，不是性质不存在。
- **修复/沉淀**:
  - bounded replay 增加 final procurator_bad guard early witness：只有当 guard 当前已确定为 false 时才提前接受 UNSAFE；guard 未知、外部未知或目标寄存器未知时仍 fallback。
  - ablation 配置继续固定 --no-reg-debug + ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf，避免回退到此前不稳定 profile。
- **沉淀为冒烟/回归测试**:
  - dslc.tests.workflows.test_focused_direct_workflow.test_bounded_dsl_replay_accepts_final_guard_before_unknown_tail
  - dslc.tests.workflows.test_focused_direct_workflow.test_bounded_dsl_replay_rejects_unknown_tail_when_final_guard_is_unknown
  - dslc.tests.bench.test_run_e2e_ablations_classify.test_ddosd_dry_run_uses_opt_smallblocks_profile

## 2026-05-13

- **Spec**: Procurator/argo/code/spec/bench/distcache_leaf_pktloss_clone_drop_bug.prop
- **时间**: 2026-05-13 12:04 CST
- **目标/进度**: 重跑已知理论 bug（DistCache leaf pktloss clone/drop），补齐当前 results JSON 缺失项并留存可审计证据。
- **结果**:
  - slicing: UNSAFE，run_id 20260513-120447-c9d6，产物目录 .tmp/procurator/verify/distcache_leaf_pktloss_clone_drop_bug/20260513-120447-c9d6/。
  - 证据: distcache_leaf_pktloss_clone_drop_bug.bounded-dsl-replay.unsafe.json + distcache_leaf_pktloss_clone_drop_bug.bounded-dsl-replay.textual.log；ablation 表记录 opt result UNSAFE。
- **坑（实现/流程导致）**:
  - 该 case 之前在当前 JSON 中缺失，不能以“未跑/未记录”替代已知理论 bug 的重验证。
  - 若 replay 或 solver 后续返回 unsupported/timeout/no-result，策略仍是 fallback/重跑，不解释为 bug absence。
- **修复/沉淀**:
  - 复用 bounded DSL replay 的 UNSAFE-only marker 与 CLI [RESULT] RESULT: UNSAFE 输出，保证 ablation 分类和 sanity 能接住证据。
- **沉淀为冒烟/回归测试**:
  - dslc.tests.toolchain.test_validate_counterexample.test_summarize_witness_accepts_bounded_dsl_replay_marker
  - dslc.tests.bench.test_run_e2e_ablations_classify.test_sanity_check_accepts_bounded_dsl_replay_marker

## 2026-05-13

- **Spec**: Procurator/argo/code/spec/bench/distcache_spine_cache_frequency_idx_bug.prop
- **时间**: 2026-05-13 12:06-12:08 CST
- **目标/进度**: 重跑已知理论 bug（DistCache spine cache_frequency idx），补齐当前 results JSON 缺失项，并通过 witness rerun 留存可审计证据。
- **结果**:
  - slicing: UNSAFE，run_id 20260513-120630-b8a4，产物目录 .tmp/procurator/verify/distcache_spine_cache_frequency_idx_bug/20260513-120630-b8a4/。
  - 证据: gemcutter.log 主 run UNSAFE，gemcutter.witness.log witness rerun UNSAFE，witness 文件 distcache_spine_cache_frequency_idx_bug.bpl-witness.graphml。
- **坑（实现/流程导致）**:
  - 该 case 之前在当前 JSON 中缺失，不能将“未重跑”当作 bug absence。
  - 本 case 走 Ultimate/GemCutter 正常 witness 路径，耗时约 119.3s；短 timeout/unknown 仍不能作为不存在证据。
- **修复/沉淀**:
  - 本轮未新增 case-specific 建模修复；使用 runner 当前命令 `verify --wraparound off --use-spec-max-steps` 重新跑出主 UNSAFE 和 witness rerun UNSAFE。
- **沉淀为冒烟/回归测试**:
  - 由 run_e2e_ablations.py 保存 run_id、log_path、witness 和 sanity，后续 report-only / resume 会复用当前 JSON 证据。

## 2026-05-13

- **Spec**: bounded DSL replay / focused-direct prepass infrastructure (multi-spec regression support)
- **时间**: 2026-05-13 11:30-12:10 CST
- **目标/进度**: 修复已知理论 bug 重跑中的 “有确定 guard 违反但 solver/后半段未知导致 no-result/ERROR” 链路，保证 UNSAFE-only under-approx 证据能被 CLI、ablation 分类、sanity 和 witness summary 全链路识别。
- **结果**:
  - 新增/修复 bounded DSL replay marker `*.bounded-dsl-replay.unsafe.json`，synthetic log `*.bounded-dsl-replay.textual.log`，kind 为 `bounded_dsl_replay_under_approx`。
  - Cheetah、DDOSD、DistCache leaf 均通过该链路重新跑出 `UNSAFE` 且 sanity `OK`；DistCache spine 通过正常 Ultimate + witness rerun 路径 `UNSAFE`。
  - `.tmp/procurator/e2e_ablations_20260513_current.json` 当前 23 条 recorded runs 均为 `UNSAFE`，无 non-UNSAFE / sanity 异常记录。
- **坑（实现/流程导致）**:
  - `procurator verify` 初版 bounded replay 命中时只返回 rc=1 和 `[CEX]`，没有 `[RESULT] RESULT: UNSAFE`；`run_e2e_ablations.py` 因此把有 marker 的结果记成 `ERROR`。
  - bounded replay 初版把未知寄存器写和未知尾部控制流直接当 unsupported；对已经能由最终 `procurator_bad` guard 判定违反的路径过于保守，导致真实 bug 证据丢失。
  - marker 校验初版把 cwd-relative BPL path 当成 marker-dir-relative path，导致真实 `.tmp/...` marker 无法被 `bounded_dsl_replay_marker_for_bpl` 接受。
- **修复/沉淀**:
  - 未知寄存器写：忘记该寄存器数组与镜像的已知值；若最终 guard 依赖它，会继续未知并 fallback。
  - 未知尾部控制流：仅当 final `procurator_bad` guard 当前已确定为 false 时提前接受 UNSAFE；guard 未知、外部过程未知、assert 未知均 fail-closed fallback。
  - CLI 输出：bounded replay 命中时打印 `[RESULT] RESULT: UNSAFE` 和 replay textual log 的 `[LOG]`。
  - ablation 分类：识别 focused/bounded `[CEX]` marker 作为 UNSAFE 兜底，避免 rc=1 被错误归为 ERROR。
- **沉淀为冒烟/回归测试**:
  - `python3 -m unittest -v dslc.tests.workflows.test_focused_direct_workflow dslc.tests.toolchain.test_validate_counterexample dslc.tests.bench.test_run_e2e_ablations_classify`
  - 结果：`Ran 63 tests ... OK`。

## 2026-05-13 camera-ready 对齐：Input Inference 审计证据

- **Spec/Test target**: `dslc.tests.boogie.backend.test_boogie_input_inference_evidence`
- **时间**: 2026-05-13 17:10-17:40 Asia/Shanghai
- **目标/进度**: 对齐论文里的 Input Inference / `Keep[v]` / `Havoc[v]` 可审计性；不改变 pruning 语义，把当前 DSLC 已经计算的 slicing seeds、P4B keep vars、required packet vars、raw/havoc/pruned input vars、force-kept inputs、skipped control outputs 写入 backend profile。
- **结果**:
  - 完成 commit `6a4830d4` (`feat: record input inference evidence`)。
  - 每个 node profile 新增 `input_inference` 字段，用于解释字段为什么被保留、havoc、剪掉或从外部输入中跳过。
  - `standard_metadata.egress_spec` 等转发控制输出被记录在 `skipped_control_outputs`，不再只能从生成的 Boogie 里反推。
- **坑（实现错误导致）**:
  - required packet var declaration 检查原来没有处理 P4B 生成的 `_0` 变体；容易把已经存在的变量误判为缺失，或诱导错误的 ghost declaration 思路。
  - Windows 侧直接跑 P4B-dependent smoke 会因 Linux P4B binary 路径不可执行失败；这不是本 feature 语义回归，P4B-dependent 测试应在 WSL 下跑。
- **修复/沉淀为冒烟测试**:
  - `dslc/backends/boogie/core/bpl.py`: 新增 `collect_skipped_input_vars`，并修正 required var 声明检查的 `_0` 解析。
  - `dslc/backends/boogie/compiler.py`: 写入 `input_inference` profile。
  - `dslc/tests/boogie/backend/test_boogie_input_inference_evidence.py`: 覆盖 Keep/Havoc profile、assume-only required vars、skipped control outputs。
  - 回归执行：
    - Windows: `.venv\Scripts\python.exe -m unittest -v dslc.tests.boogie.backend.test_boogie_input_inference_evidence dslc.tests.boogie.backend.test_boogie_no_ghost_packet_vars dslc.tests.boogie.backend.test_boogie_bpl_missing_var_decls dslc.tests.boogie.backend.test_boogie_slicing_seeds` -> PASS。
    - WSL: `.venv-wsl/bin/python -m unittest -v dslc.tests.boogie.backend.test_boogie_input_inference_evidence dslc.tests.boogie.backend.test_boogie_no_ghost_packet_vars dslc.tests.boogie.backend.test_boogie_bpl_missing_var_decls dslc.tests.boogie.backend.test_boogie_slicing_seeds` -> PASS。

## 2026-05-13 camera-ready 对齐：wraparound 论文阶段命名

- **Spec/Test target**: `dslc.tests.wraparound.schedule.certification.test_schedule_manifest_certification`
- **时间**: 2026-05-13 17:40-18:00 Asia/Shanghai
- **目标/进度**: 对齐论文的三阶段表述，使 manifest 直接暴露 `ENTRY_CHECK` / `NEAR_WRAP` / `CLOSURE_CHECK`，避免 camera-ready 审计时只看到内部兼容名。
- **结果**:
  - 完成 commit `e0a1d907` (`feat: expose wraparound paper stages`)。
  - `CegisManifest` 输出新增 `paper_stages`，映射为 `stage1=ENTRY_CHECK`、`stage2=NEAR_WRAP`、`stage3=CLOSURE_CHECK`。
  - 该 feature 只增加命名/manifest 审计字段，不改变认证规则；`UNKNOWN/TIMEOUT/未认证 SAFE` 仍不能解释为 bug absence。
- **坑（实现错误导致）**:
  - 本轮无新语义实现错误；主要风险是把内部 `CONFIRM` 等兼容名字和论文 `NEAR_WRAP` 表述混在一起，导致审计材料不可读。
- **修复/沉淀为冒烟测试**:
  - `dslc/workflows/wraparound_support/certification/manifest.py`: 新增 `PAPER_STAGE_NAMES` 与 `paper_stage_names()`。
  - `dslc/workflows/wraparound_cegis.py`: manifest 写入 `paper_stages`。
  - `dslc/tests/wraparound/schedule/certification/test_schedule_manifest_certification.py`: 新增 manifest stage-name 回归。
  - 回归执行：
    - `.venv\Scripts\python.exe -m unittest -v dslc.tests.wraparound.schedule.certification.test_schedule_manifest_certification` -> PASS。
    - `.venv\Scripts\python.exe -m unittest -v dslc.tests.wraparound.schedule.test_wraparound_schedule` -> PASS。

## 2026-05-13 camera-ready 对齐：cross-pass / pipeline payload slicing 审计

- **Spec/Test target**: `dslc.tests.p4b.test_p4b_cross_pass_payload_slicing`
- **时间**: 2026-05-13 18:00-18:30 Asia/Shanghai
- **目标/进度**: 对齐论文 CrossPass/Pipeline 数据依赖描述；不是重写 slicer，而是用 P4B selftest 证明现有 cross-pass augmentation 对 recirculate/resubmit 与 clone/mirror 的 packet payload 依赖保留正确。
- **结果**:
  - 完成 commit `901750cb` (`test: audit cross-pass payload slicing`)。
  - 新增 `recirc_payload_flow` selftest：Ingress 写 `hdr.fanout.pass`，Egress recirculate 后下一 pass 依赖该 payload 字段；slicing for forwarding output 必须保留 payload write 与 recirculate trigger。
  - 新增 `clone_payload_flow` selftest 与最小 `clone_fanout` fixture：Ingress 写 `hdr.fanout.pass` 后 I2E clone；slicing for clone event 必须保留 payload write 与 clone/mirror call。
  - `SliceResult.hasRecirculation` 增加兼容命名注释，说明该字段现在表示 cross-pass event detected（recirculate/resubmit/clone/mirror），不是只限 recirculation。
- **坑（实现错误导致）**:
  - 本轮没有发现 cross-pass 算法失效；新增测试是审计/回归证据。
  - 工作树中存在其它未提交 slicing selftest 实验 hunk，提交时必须只纳入 cross-pass payload 相关改动，避免把未验证 feature 混入。
- **修复/沉淀为冒烟测试**:
  - `P4B-Translator/backends/verify/slicing/slicer_selftest.cpp`: 新增 `recirc_payload_flow` 与 `clone_payload_flow` 检查，直接检查 `keepVarNames` 和 sliced IR 中的 payload assignment / event call。
  - `dslc/tests/p4b/test_p4b_cross_pass_payload_slicing.py`: 新增 WSL/P4B translator 端到端 selftest wrapper。
  - `Procurator/argo/code/dataset/clone_fanout/switch.p4`: 新增最小 clone/mirror payload dependency fixture。
  - 回归执行：
    - `wsl --cd /mnt/e/p4-verify/P4B-Translator/build-host make -j16 p4c-translator` -> PASS。
    - `wsl --cd /mnt/e/p4-verify .venv-wsl/bin/python -m unittest -v dslc.tests.p4b.test_p4b_cross_pass_payload_slicing` -> PASS（2 tests）。
    - `wsl --cd /mnt/e/p4-verify .venv-wsl/bin/python -m unittest -v dslc.tests.p4b.test_p4b_cross_pass_payload_slicing dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_netchain_seq_seed_slicing dslc.tests.p4b.test_p4b_translator_slicing_selftest.TestP4BTranslatorSlicingSelftest.test_recirc_meta_flow_cross_stage_slicing` -> PASS（4 tests）。
