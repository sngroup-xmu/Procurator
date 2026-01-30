# Netchain (netchain_16.p4) → Boogie 差异诊断与修复方案

本文件记录一次针对 `Procurator/argo/code/dataset/Netchain/netchain_16.p4`、控制面命令 `Procurator/argo/code/dataset/Netchain/commands_1.txt` 与生成的 Boogie（`.bpl`）之间差异的排查过程：哪些是**真实翻译 bug**，哪些是**slicing（剪枝）带来的抽象/缺失**，以及对应的修复方案与验证方式。

## 0. 你看到的“差异”来自哪一层？

同一个 P4 程序，在我们系统里会产生两类 `.bpl`：

1) **unsliced（不剪枝）**：用于语义对比/定位翻译正确性。  
2) **sliced（剪枝）**：用于验证加速；按“性质 seeds”做 backward slice，删掉看起来“与 seeds 无关”的语句/表/动作。
   - 理想情况下它应当保持 seeds 的语义；但当 seeds 选取过宽/过窄，或模型/环境约束表达不当时，会表现为过近似/欠近似，从而出现伪反例（false positive）或漏报（false negative）。

因此，“P4 源码 vs `<OUT_DIR>/netchain_bug.bpl`”看到的缺失，常常不是 translator 不会翻译，而是被 slicing 删掉了。

补充：当前 seeds 的设计遵循“职责分离”——
- `assume/assert`（约束可行性/性质可观测量）参与 seeds；
- `env { ... }` 是输入注入建模，不作为切片准则（避免把“为了构造包而写的字段”误当作性质观测量导致切片膨胀）；
- 有拓扑时由系统层补充转发/事件控制相关 seeds（否则 P4B slicer 本身不知道我们的分布式 harness/topology 语义）。

## 1. 推荐的复现/对比方式（两份输出对照）

本文统一用 `<OUT_DIR>` 表示“本次实验输出目录”。你可以手动指定一个固定目录（便于对照/引用行号），也可以直接把 `procurator` 打印出来的输出目录当作 `<OUT_DIR>`：

- 手动指定（示例）：`OUT_DIR=$PWD/.tmp/procurator/manual/netchain_diag`
- 自动生成：不传 `--out/--work-dir` 时，`./bin/procurator compile/verify` 会在 `.tmp/procurator/.../<run_id>/` 下创建新的目录（no-cache 默认），其父目录即可视为 `<OUT_DIR>`。

### 1.1 生成 unsliced（语义对照基线）

```bash
P4B-Translator/build-host/p4c-translator \
  -I P4B-Translator/p4include \
  Procurator/argo/code/dataset/Netchain/netchain_16.p4 \
  --bmv2cmds Procurator/argo/code/dataset/Netchain/commands_1.txt \
  --no-slicing \
  -o <OUT_DIR>/_noslice_s1.bpl \
  --meta-out <OUT_DIR>/_noslice_s1.meta.json
```

### 1.2 生成 sliced（验证加速用产物）

用 `procurator` 直接生成（建议先只编译，便于定位“翻译 vs slicing”差异）：

```bash
./bin/procurator compile \
  --spec Procurator/argo/code/spec/bench/netchain_bug.prop \
  --out <OUT_DIR>/netchain_bug.bpl \
  --work-dir <OUT_DIR>/netchain_bug.work
```

如需在同一份 `.bpl` 上跑 Ultimate/GemCutter（可选）：

```bash
./bin/procurator verify \
  --spec Procurator/argo/code/spec/bench/netchain_bug.prop \
  --out <OUT_DIR>/netchain_bug.bpl \
  --work-dir <OUT_DIR>/netchain_bug.work \
  --ultimate <PATH_TO_ULTIMATE>
```

输出通常在：`<OUT_DIR>/netchain_bug.bpl` 和 `<OUT_DIR>/netchain_bug.work/*.raw.bpl`。

## 2. 逐项差异：根因与结论

下面按你列出的条目分类说明（“真实翻译 bug” vs “剪枝导致的缺失/重写”）。

### 2.1 parser：`packet.extract(...)` / `s1_packet_in.extract`

**现象**  
你关注到 parser 里有 `packet.extract(...)`，在 `.bpl` 中看到 `s1_packet_in.extract(...)` 等调用。

**结论**  
这部分大体是符合预期的：在 goto 版本（dslc 默认生成 `--goto`）里，extract 会以过程调用形式出现，例如 `<OUT_DIR>/netchain_bug.bpl` 中 `parse_overlay` 会调用：

```
call s1_packet_in.extract.headers.overlay.next(s1_hdr.overlay);
```

而在非 goto 输出里，translator 可能把 `packet.extract(hdr.xxx)` 抽象为 “仅设置 valid”，这属于建模选择，不等价于缺失语义（字段值本身仍是符号化/不建模 payload 的常见抽象）。

### 2.2 ingress：没调 `get_sequence.apply()` / `get_sequence_act` 空 / `read_value.apply()` 缺失

**现象**（多发生在 sliced 输出）  
在 `<OUT_DIR>/netchain_bug.work/s1.raw.bpl` 里：
- `get_sequence_0.apply()` 不见了（ingress 不再调用）
- `get_sequence_act()` 变成空过程
- `read_value_0.apply()` 不再被调用（对应分支直接空）

**根因**  
这是 **P4B slicing（剪枝）** 的结果，不是 translator “不会翻译”：
- 在 unsliced 输出 `<OUT_DIR>/_noslice_s1.bpl` 中，`get_sequence_0.apply()` 和 `read_value_0.apply()` 都存在且被 ingress 调用。
- sliced 输出会把它们当作“与 slicing 种子无关”，从而删掉表调用或删空动作体，把相关变量变成“外部输入般的 nondet”。

**为什么会影响语义/可能导致伪反例？（关键例子）**  
P4 源码 `netchain_16.p4` 的逻辑（节选）：

```p4
get_sequence.apply();
...
if (meta.my_md.role == 16w100 || hdr.nc_hdr.seq > meta.sequence_md.seq) {
    assign_value.apply();
    pop_chain.apply();
} else {
    drop_packet.apply();
}
```

如果 slicing 把 `get_sequence` 读寄存器删掉，但保留了后面的比较条件，那么 `meta.sequence_md.seq` 就会被当成“自由变量”，从而允许走到本不该走的路径（过近似），进而产生伪反例。

**修复/对策（建议）**
- 做语义对照时用 `--no-slicing`（见 §1.1），先确认 translator 本体翻译是对的。
- 若要在 sliced 模式下减少伪反例，需要让 slicing 更保守：至少把“影响关键分支条件的变量/表”加入 slicing 种子（例如把 `meta.sequence_md.seq` 及其依赖的 `get_sequence` 保留下来），或者引入“控制依赖”切片（更完整但代价更高）。

### 2.3 “多了一个 `&& (hdr.nc_hdr.seq != meta.sequence_md.seq)`”

**现象**  
你看到 Boogie 条件写成了类似：
```
(hdr.nc_hdr.seq >= meta.sequence_md.seq) && (hdr.nc_hdr.seq != meta.sequence_md.seq)
```

**结论**  
这通常是把 `>` 变成 `>= && !=` 的等价改写（在 bitvector/无符号比较实现里很常见），属于**语义等价**，不应视为 bug。

### 2.4 `find_index`：key=2028 分支缺少 `index := 4`

**现象**（unsliced 与 sliced 都会出现，属于真 bug）  
在旧输出里，`find_index_0.apply()` 对 `hdr.nc_hdr.key == 2028` 的分支缺少：
```
find_index_0.find_index_act.index := 4bv16;
```
导致后续 `call find_index_act(find_index_0.find_index_act.index);` 使用了未初始化/任意值。

**根因（已定位）**  
控制面命令 `commands_1.txt` 的最后一行**没有换行符**，且 action 参数是单字符 `4`。  
BMV2 CLI 命令解析的 `split()` 有一个边界条件 bug：当最后 token 只有 1 个字符且文件末尾无 `\\r/\\n` 时，它会被漏掉，导致 `TableAdd.parameters` 为空。

**修复（已完成）**  
`P4B-Translator/backends/verify/translate/bmv2.cpp`：修正 `split()` 的尾 token 处理（`idx1 < str.length()`）。

**修复后验证**  
重新编译 `p4c-translator` 并生成 `<OUT_DIR>/_noslice_s1.bpl` 或 `<OUT_DIR>/netchain_bug.bpl`，应能看到 `2028` 分支出现 `index := 4bv16;`。

### 2.5 `maintain_sequence_act` 少 read / `assign_value_act` 少 `value_reg.write` / `drop_packet_act` 少 `mark_to_drop` / `gen_reply_act` 少 `udp.dstPort=8889`

**结论**  
这些在 unsliced 输出中是存在的；在 sliced 输出中被删掉属于 slicing 的过近似抽象（与 §2.2 同类问题）。

## 3. 下一步建议（让“验证快”且“伪反例少”）

如果目标是“既能找 bug，也能在部分场景可证明”，建议把 slicing 与反例确证做成一个流程：

1) 默认用 sliced 模型跑（快，bug-finding 强）。  
2) 一旦 UNSAFE：自动触发 “确证”：
   - 用 `./bin/procurator verify --no-slicing`（禁用 slicing）或更保守的 slicing 重新跑一次（同样的 env 约束/同样的 trace 引导）
   - 若 UNSAFE 仍成立，认为是更可信的真实反例；否则把它当作伪反例并记录“被哪条语义补全消掉”。

这相当于对 slicing 抽象做一个轻量的 CEGAR（反例驱动精化），可以把我们之前踩到的“伪反例”系统化收敛掉，而不需要一开始就把模型做得很重。

## 4. Netchain 分布式验证 spec 解析 + 踩坑/修复报告

这一节把我们最近用于复现/定位 Netchain “翻转（wrap-around）bug” 的 `.prop` 规格文件解释清楚，并记录“为什么之前跑出来的 trace 看起来不合理/剪枝前后不一致/跑不出来预期反例”等一系列坑，以及对应的修复点。

### 4.1 规格文件清单（bench）

这些 spec 都在：`Procurator/argo/code/spec/bench/`

- `netchain_bug.prop`：3 节点（s1→s2→s3）版本；验证两个单调性关系：`s1>=s2` 与 `s2>=s3`。
- `netchain_bug_s1s2.prop`：2 节点（s1→s2）缩减版本；只验证 `s1>=s2`，方便做 slicing/不 slicing 的语义对照与性能对比。
- `netchain_bug_s1s2_fastforward.prop`：2 节点 “fast-forward” 版本；通过一个 *reachability cut* 把系统直接带到“两个副本 seq 都在 65535”的可达中间态，然后只跑 2 步触发 16-bit wrap-around，快速 sanity-check 语义与剪枝一致性。

### 4.2 `.prop` 在我们系统里意味着什么？（面向 Boogie harness）

#### 4.2.1 `import ... entries ...`

每个节点的 `import s1 from netchain_16.p4 entries commands_1.txt;` 表示：

- 用同一个 P4 程序实例化多个节点（s1/s2/s3）。
- 每个节点使用不同的控制面命令文件 `commands_i.txt`（常见差异：role/ip、表项参数等）。

#### 4.2.2 `topology { link s1 -> s2 ALL; }`

拓扑决定“从某节点 egress 发出的包被入队到哪个下游节点 inbox”。

#### 4.2.3 `node s1 { external_input = true; assume { ... } }`

`external_input=true` 表示该节点允许接收外部注入包（EnvThread/host model）。

`assume { ... }` 这一大段本质是在做“输入收紧”：把 **原本任意的符号化包字段** 限制成 Promela 里 host_h1 的那种包形状。例如：

- `hdr.*.valid`：哪些 header 必须 valid（以及哪些必须 invalid）。
- `hdr.ipv4.protocol==17`：UDP 包。
- `hdr.overlay.{0,1,2,3}.swip`：约束 overlay 栈（例如 3 节点版本里是 s1→s2→s3→host）。
- `hdr.nc_hdr.op==12` / `hdr.nc_hdr.key==2024`：只发写请求，并固定到能走到 `find_index` 的 `index=0` 路径。

这类收紧非常关键：否则验证器会花大量精力探索“对 bug/性质完全无关”的输入分支，表现为跑很慢、trace 不可读、甚至诱发伪反例。

#### 4.2.4 `global { ... assume { ... } assert { ... } }`

`global.assume` 是对所有节点共享的额外收紧/固定（例如强制 `meta.location.index==0`、固定 `role`、强制 `find_index.hit==true`、避免 egress_port=0 导致的 drop）。

`global.assert` 是我们目前验证的“性质”。需要注意：当前 Boogie 后端把性质当作 **safety**（断言），并在 *每一个 pass* 后检查一次，因此：

- LTL 里的 `[] P`（always）现在等价于“每步 assert P”。
- 但更一般的 LTL（例如 liveness / until）还没有原生后端支持，需要另行引入自动机/监视器编码。

### 4.3 Netchain “翻转 bug” 的直观含义（为什么会出现 65535 与 0）

Netchain 的 `sequence_reg` 是 `bv16`（16 位无符号 bitvector），按模 `2^16` 算术运行：

- `65535`（`2^16-1`）再加 1 会 wrap 成 `0`。
- 我们希望保持副本之间的“单调关系”（例如 `s1_sequence_reg[0] >= s2_sequence_reg[0]`），但 wrap-around 会让这个关系瞬间失效：
  - 例：`s1=0`、`s2=65535`，此时 `s1>=s2` 不成立。

`netchain_bug_s1s2_fastforward.prop` 的目标就是把系统带到这种“临界点附近”，快速得到预期反例。

### 4.4 我们踩过的坑（症状→根因→修复点）

#### 4.4.1 伪反例：寄存器初值不符合语义（导致“凭空违反”）

**症状**

- trace 里寄存器在第一步就出现莫名其妙的值，导致断言被违反；
- 或者你感觉反例与 P4 语义不一致（比如没走写路径也违反了）。

**根因**

在 P4 语义里，寄存器初值应该要么由控制面显式指定，要么默认视为 0。若模型把寄存器当成自由变量（havoc），会产生大量“凭空状态”，很容易出现伪反例。

**修复**

在 Boogie harness 的初始化里，为所有寄存器数组生成显式零初始化约束（同时也给 index=0 单独一条，便于读 witness）：

- 实现位置：`dslc/backends/boogie_harness.py` 的 `_emit_register_init_assumes()`

你可以在 Ultimate witness/log 里直接看到类似（示例来自 `.tmp/regress/netchain/maxindex5/slice/run.gemcutter.log`）：

- `assume (forall i : bv32 :: s2_sequence_reg[i] == 0bv16);`
- `assume s2_sequence_reg[0bv32] == 0bv16;`

#### 4.4.2 剪枝与“不剪枝”跑出来的东西不一致：regMaxIndex 推导/传递错误

**症状**

- slicing 后“跑不出”预期反例（或反例形状变得很奇怪），但 `./bin/procurator verify --no-slicing`（禁用 slicing）又能跑出；
- 或者 slicing 后寄存器相关数组/索引没有被有效约束，性能极差；
- 或者 Boogie 里出现 ill-typed 的索引约束（Ultimate typecheck 失败）。

**根因（叠加导致）**

1) `dslc` 在收集 slicing seeds 时，曾经会把 `sequence_reg_0[0]` 这种带下标的 seed 简化成 `sequence_reg_0`，导致 P4B slicer 无法从 seeds 推出“最大寄存器 index=0”。  
2) P4B slicer 在收集 register 索引时，曾经没有区分 P4_16 与 bmv2/P4_14 的 `read` 参数签名：  
   - P4_16：`read(out value, index)`（index 是第 2 个参数）  
   - bmv2：`read(index)`（index 是第 1 个参数）  
   这会直接把 “out 变量” 当成 index，从而把 `regMaxIndex` 推错/推不出来。
3) translator 在插入索引上界约束时，曾经直接用 `<` 比较 bitvector（例如 `assume idx < 1bv32`），这在 Boogie/Ultimate 里是类型不匹配的（bitvector 需要用 `bvule/bvult` 这类 builtin）。

**修复（分别在各自模块完成，保持单一职责）**

- `dslc/backends/boogie_seeds.py`：`build_slicing_plan()` 保留 `[idx]` 形式的 seeds，并同时补全 base/`_0` 变体，兼容 P4B 的命名规则。
- `P4B-Translator/backends/verify/slicing/slicer.cpp`：`RegisterIndexCollector` 按参数个数区分 P4_16 vs bmv2 的 `read`，正确提取 idx 参数位置。
- `P4B-Translator/backends/verify/translate/translate.cpp`：对 bitvector idx 用 `bvule.bvXX$builtin(idx, max)` 形式发出上界约束，避免 ill-typed Boogie。

#### 4.4.3 BoogiePrefixer 破坏了 builtin/inline（导致 Ultimate 报 undefined）

**症状**

- Ultimate 报类似：`unknown function bvule.bv32$builtin`，或 inliner 失效导致性能/可读性变差。

**根因**

我们做多节点组合时需要做变量前缀化，但曾经把 Boogie 自带的 builtin（如 `bvule.bv32$builtin`）和属性（如 `{:inline 1}`）也错误地前缀化了，导致符号不存在/语义变。

**修复**

- `dslc/backends/boogie_prefix.py`：`BoogiePrefixer` 跳过 `bv*.bv*($builtin)` 这类名字；并将 `inline` 加入关键字集合，避免把 `{:inline 1}` 改写成 `{:s1_inline 1}`。

#### 4.4.4 fast-forward spec 里的跨节点写：modifies clause 缺失（Ultimate typecheck fail）

**症状**

fast-forward spec 在 `node s1` 里写了 `s2_sequence_reg_0[0] = 65535;`，Ultimate 会报：

> Global variable s2_sequence_reg modified in procedure s1Thread but not in modifies clause

**根因**

node thread 的 `modifies` 只收集了“节点自己的变量 + P4 mainProcedure modifies”，没有把 DSL 语句里写到的跨节点全局变量纳入。

**修复**

- `dslc/backends/boogie_harness.py`：新增 `_collect_dsl_modified_boogie_vars()`，把每个节点 DSL 的 LHS（包含跨节点的 `s2_sequence_reg_0[0]`）加入该节点线程的 modifies 集合。

#### 4.4.5 trace 解读坑：为什么同一个寄存器同时出现 0 和 65535？

**现象**

你会在 witness 里同时看到两类变量，例如：

- `s2_sequence_reg__dbg0 = 65535bv16`（反例时刻的快照）
- `s2_sequence_reg__last0_value = 0bv16`（看起来像“最近写入的值是 0”）

**解释**

`__dbg0` 是我们在断言点显式拷贝的“寄存器真实值快照”：`s2_sequence_reg__dbg0 := s2_sequence_reg[0bv32];`  
而 `__last0_value`/`__wrote_index0` 是“通过 register.write() 过程写寄存器”时的写追踪变量。

在 `netchain_bug_s1s2_fastforward.prop` 里，我们用的是 **直接赋值**：

```prop
s2_sequence_reg_0[0] = 65535;
```

它不会经过 `write()` 过程，因此 “写追踪变量”仍保持初始化值（0），但寄存器真实值已经被直接赋成 65535。这是符合我们当前插桩设计的。

**建议**

- 判断性质是否真的被违反：优先看 `*_sequence_reg__dbg0`（或直接看 `sequence_reg[0]` 的快照），而不是 `__last0_value`。
- 如果希望 `__last0_value` 总是与寄存器一致：要么避免直接赋值、强制走 `write()` 路径；要么把 DSL 直接赋值也同步更新写追踪变量（这属于插桩语义选择，需要单独讨论）。

### 4.5 最小复现命令（无超时）

```bash
./bin/procurator verify \
  --spec Procurator/argo/code/spec/bench/netchain_bug_s1s2_fastforward.prop \
  --p4b-bin P4B-Translator/build-host/p4c-translator \
  --ultimate UGemCutter-linux/Ultimate \
  --ultimate-timeout-seconds 0
```

运行时会输出一个 `<OUT_DIR>`（形如 `.tmp/procurator/verify/<spec>/<run_id>/`）。日志默认在：`<OUT_DIR>/gemcutter.log`。如果你看到类似：

- `s1_sequence_reg__dbg0=0bv16`
- `s2_sequence_reg__dbg0=65535bv16`
- `assert bvule.bv16$builtin(s2_sequence_reg__dbg0, s1_sequence_reg__dbg0);`

那就是我们要的 “wrap-around 导致单调性被破坏” 的预期反例形状。

---

## 5. `netchain_16.p4` ↔ `.bpl` 逐行对照（以 `netchain_bug_s1s2.seq.bpl` 为例）

这一节的目标是回答你“现在生成出来的 `.bpl` 是否忠实于 P4 语义？”——我们把 **P4 源码**和 **当前验证用的 Boogie** 做一个“按模块/按语句形状”的对应表，并指出哪些地方是 **P4B/验证建模的抽象**（不是翻译漏了），哪些地方是真正需要修的翻译问题。

对照文件：

- P4：`Procurator/argo/code/dataset/Netchain/netchain_16.p4`
- 控制面：`Procurator/argo/code/dataset/Netchain/commands_1.txt`、`Procurator/argo/code/dataset/Netchain/commands_2.txt`
- Boogie：`<OUT_DIR>/netchain_bug_s1s2.seq.bpl`

### 5.0 先看 `<OUT_DIR>/netchain_bug_s1s2.seq.bpl` 的结构（哪些是 P4 翻译，哪些是 harness）

这份 `.bpl` 是“节点 P4 翻译 + 分布式 harness”拼在一起的：

- `// ===== BEGIN NODE s1 (prefixed) =====`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:10`）到 `// ===== END NODE s1 =====`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:1125`）
  - 这部分基本就是把 `netchain_16.p4` 翻译成 Boogie，并加上 `s1_` 前缀（同一份 P4 实例化成节点 s1）。
- `// ===== BEGIN NODE s2 (prefixed) =====`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:1127`）到 `// ===== END NODE s2 =====`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:2176`）
  - 同理，加上 `s2_` 前缀（节点 s2）。
- `// ===== BEGIN ENQUEUE PROCEDURES =====`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:2178`）之后
  - 这是 **分布式/调度/环境注入** 的 Boogie harness（不属于 P4 语言本身），例如 `s1__enqueue_s2`、scheduler、assert 检查点等。

所以做“P4 vs Boogie 翻译正确性”对照时，优先看 **NODE s1/s2** 两段。

### 5.1 Parser：P4 `ParserImpl` ↔ Boogie `s1_ParserImpl` / `s2_ParserImpl`

P4 parser 在 `netchain_16.p4:105` 开始：

- P4：`parse_ethernet`（`netchain_16.p4:109`）  
  Boogie：`s1_State$ParserImpl$parse_ethernet`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:381`）
  - P4：`packet.extract(hdr.ethernet)`（`netchain_16.p4:110`）  
    Boogie：`call s1_packet_in.extract(s1_hdr.ethernet)`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:382`）
  - P4：`select(hdr.ethernet.etherType)`（`netchain_16.p4:111`）  
    Boogie：用 `goto` + `assume` 分出两支（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:383-391`）

- P4：`parse_ipv4`（`netchain_16.p4:116`）  
  Boogie：`s1_State$ParserImpl$parse_ipv4`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:393`）
  - P4：`hdr.ipv4.protocol = 8w17`（`netchain_16.p4:118`）  
    Boogie：`s1_hdr.ipv4.protocol := 17bv8`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:395`）

- P4：`parse_udp`（`netchain_16.p4:144`）  
  Boogie：`s1_State$ParserImpl$parse_udp`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:442`）
  - P4：`hdr.udp.dstPort = 16w8888`（`netchain_16.p4:146`）  
    Boogie：`s1_hdr.udp.dstPort := 8888bv16`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:444`）

- P4：`parse_overlay`（`netchain_16.p4:133`）  
  Boogie：`s1_State$ParserImpl$parse_overlay`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:426`）
  - P4：`packet.extract(hdr.overlay.next)`（`netchain_16.p4:134`）  
    Boogie：`call s1_packet_in.extract.headers.overlay.next(s1_hdr.overlay)`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:427`）
  - P4：`select(hdr.overlay.last.swip)`（`netchain_16.p4:135`）  
    Boogie：`assume (s1_hdr.overlay.last.swip == 0bv32)` 分支到 `parse_nc_hdr`，否则回到 `parse_overlay`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:430-436`）

- P4：`parse_nc_hdr`（`netchain_16.p4:125`）  
  Boogie：`s1_State$ParserImpl$parse_nc_hdr`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:410`）

**重要的建模抽象（不是翻译 bug）**

- `s1_packet_in.extract(...)` 在 `.bpl` 里是“声明 + ensures”，没有实现（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:932-937`）：
  - 它只保证 `hdr.xxx` 变成 valid（`ensures (s1_isValid[s1_header] == true)`），字段值本身仍然来自环境注入（符号化）。
  - 这也是为什么 `.prop` 里要用 `assume` 把 `hdr.*` 收紧成“像 Promela host 发的包”。

### 5.2 Ingress：P4 `ingress.apply { ... }` ↔ Boogie `s1_ingress()` / `s2_ingress()`

P4 的 ingress apply 在 `netchain_16.p4:324` 开始，对应：

- Boogie：`procedure {:inline 1} s1_ingress()`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:793-833`）
- Boogie：`procedure {:inline 1} s2_ingress()`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:1844-1884`）

以 s1 为例（结构几乎 1:1）：

- P4：`if (hdr.nc_hdr.isValid())`（`netchain_16.p4:325`）  
  Boogie：`if(s1_isValid[s1_hdr.nc_hdr])`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:796`）

- P4：`get_my_address.apply()`（`netchain_16.p4:326`）  
  Boogie：`call s1_get_my_address_0.apply()`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:797`）

- P4：`find_index.apply(); get_sequence.apply();`（`netchain_16.p4:328-329`）  
  Boogie：`call s1_find_index_0.apply(); call s1_get_sequence_0.apply();`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:799-800`）

- P4：`if (hdr.nc_hdr.op == 8w10) read_value.apply();`（`netchain_16.p4:330-332`）  
  Boogie：`if((s1_hdr.nc_hdr.op == 10bv8)) call s1_read_value_0.apply();`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:801-803`）

- P4：写路径（`netchain_16.p4:334-345`）  
  Boogie：写路径（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:805-816`）
  - `role == 100` 时先 `maintain_sequence`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:806-808`）
  - `role == 100 || hdr.nc_hdr.seq > meta.sequence_md.seq` 时走 `assign_value; pop_chain`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:809-812`）

**你之前关心的“多了一个 `&& (seq != meta.seq)`”**

在 Boogie 里，`hdr.nc_hdr.seq > meta.sequence_md.seq` 往往会被编码成：

```
((sub.bv17(0bv1 ++ seq, 0bv1 ++ meta_seq))[17:16] == 0bv1) && (seq != meta_seq)
```

这是一种常见的 bitvector 无符号比较实现方式（`>` ≡ `>= && !=`），属于等价改写，不是语义 bug。

### 5.3 关键 action：P4 action ↔ Boogie procedure（s1 版行号）

P4 ingress action 定义从 `netchain_16.p4:177` 开始。下面列出我们这次排查中最关键的几个（你之前列的那些“缺失点”也在这里）：

- `assign_value_act`：`netchain_16.p4:177-180`  
  ↔ `s1_assign_value_act`：`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:489-497`  
  - 已包含 `sequence_reg.write(...)` 和 `value_reg.write(...)`（你之前提的 “value_reg write 缺失” 在当前输出里已修复）。

- `drop_packet_act`：`netchain_16.p4:181-183`  
  ↔ `s1_drop_packet_act`：`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:516-520`  
  - Boogie 里对应 `call s1_mark_to_drop()`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:519`），不再是空动作。

- `pop_chain_act`（含 `hdr.overlay.pop_front(1)`）：`netchain_16.p4:184-189`  
  ↔ `s1_pop_chain_act`：`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:951-987`  
  - `pop_front(1)` 在 Boogie 里被展开成“字段搬移 + valid 搬移 + 最后一个置 invalid”（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:955-984`），这也是你之前怀疑 “pop_front 没实现” 的核心点。

- `gen_reply_act`（含 `hdr.udp.dstPort = 8889`）：`netchain_16.p4:194-201`  
  ↔ `s1_gen_reply_act`：`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:721-730`  
  - `udp.dstPort := 8889bv16` 已存在（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:729`）。

- `get_sequence_act`（read 序列号寄存器）：`netchain_16.p4:222-224`  
  ↔ `s1_get_sequence_act`：`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:784-790`  
  - `s1_meta.sequence_md.seq := s1_sequence_reg.read(...)`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:789`）

- `maintain_sequence_act`（+1, write-back, read-back）：`netchain_16.p4:229-233`  
  ↔ `s1_maintain_sequence_act`：`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:913-923`  
  - “write 后再 read 回 hdr.nc_hdr.seq” 已存在（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:920-923`）。

- `read_value_act`：`netchain_16.p4:234-236`  
  ↔ `s1_read_value_act`：`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:1059-1064`

### 5.4 控制面表项：`commands_*.txt` ↔ Boogie 的 if-else 表展开

控制面在 `commands_1.txt/commands_2.txt` 中。翻译到 Boogie 后，表项就是一串 if-else：

- `get_my_address` 默认项：
  - `commands_1.txt:18`：`table_set_default get_my_address get_my_address_act 10.0.100.1 100`  
    ↔ `s1_get_my_address_0.apply`：`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:733-744`（`sw_ip := 167797761bv32; sw_role := 100bv16`）
  - `commands_2.txt:20`：`... 10.0.100.2 101`  
    ↔ `s2_get_my_address_0.apply`：`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:1783-1795`（`sw_ip := 167797762bv32; sw_role := 101bv16`）

- `find_index` 的 2024..2028 映射：
  - `commands_1.txt:20-24`  
    ↔ `s1_find_index_0.apply`：`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:645-687`（你之前指出的 `2028 => 4` 分支缺失，现在已经是 `index := 4bv16`：`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:678-683`）

- `ipv4_route`：
  - `commands_1.txt:1-5`、`commands_2.txt:1-5`  
    ↔ `s1_ipv4_route_0.apply`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:835+`）、`s2_ipv4_route_0.apply`（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:1886+`）

### 5.5 分布式语义（harness）里最关键的“保真点”

这一部分不属于 P4 语言翻译，但它直接决定“分布式验证是不是在验证一个正确的系统语义”。

#### 5.5.1 跨节点转发只复制 on-wire 字段（`hdr.*`），不复制 `meta.*`

在真实数据面里，跨交换机传输的是包比特流（header/payload），**不会携带上一跳的 `metadata`**。

对应的 Boogie 位置是 enqueue：

- `s1__enqueue_s2()`：`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:2179-2225`

你可以看到它只复制 `s2_hdr.* := s1_hdr.*`（例如 `<OUT_DIR>/netchain_bug_s1s2.seq.bpl:2183-2222`），没有任何 `s2_meta.* := s1_meta.*`。

这点如果做错，会制造大量“伪反例/漏判”（因为 meta 被错误共享，等价于把多个节点当成同一个进程）。

#### 5.5.2 scheduler 是“串行化的 pass step”（当前是 deterministic round-robin）

`<OUT_DIR>/netchain_bug_s1s2.seq.bpl` 的调度入口在 `safety_checker_step()`（大约从 `<OUT_DIR>/netchain_bug_s1s2.seq.bpl:2332` 开始）。

当前实现是按 `procurator_phase` 做 round-robin：

- phase 0：env 注入到 s1（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:2336`）
- phase 1：s1 ingress pass（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:2438`）
- phase 2：s1 egress + enqueue（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:2462`）
- phase 3：s2 ingress pass（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:2507`）
- phase 4：s2 egress（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:2531`）
- 然后 `procurator_phase := procurator_phase + 1` / 归零（`<OUT_DIR>/netchain_bug_s1s2.seq.bpl:2579-2582`）

这解释了为什么它叫“串行化输出”：每一步只做一件事（注入/某节点 ingress/某节点 egress），而不是把多个线程并发跑。

> 注意：deterministic schedule 会带来**漏判（false negative）风险**（少探索一些交错）。它更适合做“翻译保真/语义 sanity check”。如果要做“分布式并发语义的完备探索”，仍然需要 nondet 选择（例如 `havoc choice; assume 0<=choice<k;`）。
