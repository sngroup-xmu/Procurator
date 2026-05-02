以下内容分两部分：
# 注意（最高优先级）：1、需要每次修改完之后对于之前能找到的bug，之前翻译正确的p4程序，都依旧能够正常工作。这需要设计并运行回归测试。 2、运行完单个spec的实验之后，需要在AGENTS.md中记录完成情况，包括spec，时间，完成进度，是否有实现错误导致的坑，是否修复并沉淀为冒烟测试这几项
1. **Procurator（分布式 P4 状态化验证）设计文档（可直接丢进 agent 工具作为执行规范）**——各小节均给出参考依据与引用。


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
