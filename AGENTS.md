以下内容分两部分：

1. **Procurator（分布式 P4 状态化验证）设计文档（可直接丢进 agent 工具作为执行规范）**——各小节均给出参考依据与引用。
2. **技术选型建议：P4b / GemCutter / Deagle 怎么看、怎么先试**（以最快起实验结果为目标）。

---

# 设计文档：Procurator vNext（P4 分布式状态化验证：BMC + 证明取向后端 + P4-aware 优化）

## 0. 摘要

Procurator vNext 面向“多交换机部署的状态化 P4 应用”，以**统一的 pass 原子并发语义**建模分布式执行，并通过**队列抽象分层、P4 state 读写集/可交换性约简、入口环境最小化**等 P4-aware 优化显著降低状态空间。验证引擎采用“双后端”：**BMC 模式**用于强 bug-finding；**证明取向模式**优先对接 Ultimate/GemCutter，以 commutativity 驱动的 CEGAR/泛化提升证明覆盖率。GemCutter 作为并发证明取向工具，其核心基于“语句可交换性（commutativity）”来削减交错与提升泛化能力。([Ultimate PA][1])

---

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

## 10. 实施里程碑

### M1：可运行基线

* [ ] 统一事件语义：pass + enqueue/dequeue + mirror/recirc 的最小子集
* [ ] Q2(bag,K) 建模与性质断言模板
* [ ] 输出反例 trace（跨节点事件序列）

**验收**：至少 1 个含 recirc/mirror 的 microbenchmark 可稳定复现反例或在给定界内 UNSAT。

### M2：P4-aware R/W 分析 + 约简开关

* [ ] 从 IR 提取 object×key 的 R/W
* [ ] 独立性约简（disjoint ⇒ commute）
* [ ] 消融实验脚本与报表

**验收**：在 ≥2 个基准上给出显著状态/时间下降曲线。

### M3：接入 GemCutter（Proof mode）

* [ ] 生成 Boogie 并构造并发模型（线程/调度/队列抽象）
* [ ] 对 ≥1 类 safety 性质实现 proof attempt
* [ ] 输出“证明成功/失败原因”诊断（例如 commutativity 判定回退比例）

**验收**：至少一个基准在 proof mode 下从 UNKNOWN/timeout 变为可证明或显著提速。

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

# 建议的“先试试”组合（最小成本、最快出曲线）

1. **前端**：P4b/P4B-Translator → Boogie（先把单节点 pass 语义落地，再叠加分布式事件/队列）([feihe.github.io][5])
2. **后端**：Ultimate/GemCutter（proof mode）+（可选）Ultimate 其他工具链做 sanity check（同属 Ultimate 框架）([Ultimate PA][1])
3. **实验优先级**：先做队列抽象分层与 R/W 独立性约简的消融，再决定是否引入 Deagle 作为并发 BMC baseline。([多伦多大学计算机科学系][3])

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
