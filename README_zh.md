# Procurator

[English](README.md) | [中文](README_zh.md)

Procurator 是一个面向分布式、有状态 P4 系统的开源验证器。

它读取声明式 `.prop` 网络规格，用仓库内固定的 P4B/p4c 后端翻译 P4
程序，生成分布式 Boogie harness，再调用 Ultimate/GemCutter 查找反例或验证
有界安全性。

第一次使用时，建议先看 [教程](docs/tutorial.md)，运行命令时配合
[CLI 参考](docs/cli.md) 查看参数。

## 核心能力

- 用 P4 程序、表项、拓扑、主机流量、环境假设和全局安全性质描述系统。
- 建模分布式 packet flow，包括 host、link、节点本地状态、队列和 actor 调度。
- 为并发或顺序执行生成 Boogie harness。
- 用 `src/p4b/source/` 中的 P4B/p4c fork 处理 P4 本地语义。
- 用 `src/dslc/` 中的 DSLC 编译器生成分布式 harness 和验证工作流。
- 调用 Ultimate/GemCutter，并使用仓库内固定的 toolchain/profile。
- 保存反例证据，包括 Boogie 文件、solver 日志、witness、bounded replay 记录和
  wraparound manifest。
- 提供可运行 benchmark 与 `artifact/` 下的归档结果数据。

## 安装

涉及 P4B 或 solver 的运行建议使用 Linux 或 WSL。

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r src/dslc/requirements.txt
```

构建 P4B translator：

```bash
mkdir -p src/p4b/source/build-host
cd src/p4b/source/build-host
cmake -DP4C_USE_GOLD=OFF -DENABLE_GTESTS=OFF ..
cmake --build . --target p4c-translator -j"$(nproc)"
cd -
```

安装固定版本的 Ultimate/GemCutter runtime：

```bash
artifact/scripts/setup_gemcutter.sh
export ULTIMATE="$PWD/.tmp/procurator/toolchains/gemcutter/UGemCutter-linux/Ultimate"
```

## 快速开始

把一个 NetChain 规格编译成 Boogie：

```bash
./src/bin/procurator compile \
  --spec benchmarks/specs/smoke/netchain_bug.prop \
  --out .tmp/procurator/examples/netchain_bug.bpl
```

运行结构化 harness 检查：

```bash
./src/bin/procurator smoke \
  --bpl .tmp/procurator/examples/netchain_bug.bpl \
  --harness concurrent
```

验证 NetChain wraparound 示例：

```bash
./src/bin/procurator verify \
  --spec benchmarks/specs/bench/netchain_wraparound_bug.prop \
  --ultimate "$ULTIMATE" \
  --toolchain ReachSafety.xml \
  --settings ReachSafety-32bit-GemCutter-internal.epf
```

`UNSAFE` 表示 Procurator 在生成模型中找到了违反性质的执行。`SAFE` 表示所选
模型和 bound 通过。`TIMEOUT`、`UNKNOWN`、OOM、toolchain 错误、缺失 witness
以及未经审计的 `SAFE` 都只能视为 inconclusive。

## CLI

`./src/bin/procurator` 是公开命令入口。

```text
procurator compile     将 .prop 规格编译为 Boogie 或 Promela
procurator verify      编译 .prop 并运行 Ultimate/GemCutter
procurator smoke       不调用 solver，只检查生成的 Boogie 结构
procurator wraparound  运行显式 wraparound pipeline
procurator ablation    运行 symmetry、splitting、slicing 消融
```

`procurator verify` 默认使用 `ReachSafety.xml` 和
`ReachSafety-32bit-GemCutter-internal.epf`。该 profile 是正式源码资产，位于
`src/dslc/toolchain/ultimate/settings/gemcutter/base/`。`ALL`、8g、12g、witness
等 profile 适合显式需要对应行为的运行。

更多参数和执行细节见 [docs/cli.md](docs/cli.md)。

## 设计概览

Procurator 的核心边界是 P4B 与 DSLC。

P4B 是 P4 本地编译后端。它解析 P4，降低 parser、control、table、register
行为，并输出 Boogie procedure 与 metadata。

DSLC 是分布式系统建模层。它解析 `.prop`，连接拓扑、主机、队列、actor 调度、
环境假设和全局断言，并负责 wraparound 加速、solver 调用和证据归档。

运行链路是：

```text
.prop specification
  -> P4B import translation
  -> DSLC distributed harness generation
  -> Boogie output
  -> Ultimate/GemCutter execution
  -> logs, witnesses, manifests, actual JSON
```

更完整的结构说明见 [architecture](docs/design/architecture.md)。

## 文档入口

- 学习 DSL 和规格写法：
  [教程](docs/tutorial.md) 与 [DSL 语言说明](docs/design/dsl-language.md)。
- 运行 Procurator：
  [CLI 参考](docs/cli.md) 与 [常见问题](docs/troubleshooting/known-issues.md)。
- 让 agent 操作工具：
  [agent skill](docs/agent/SKILL.md)。
- 理解实现：
  [architecture](docs/design/architecture.md) 与
  [wraparound certification](docs/design/wraparound-certification.md)。
- 解读归档结果：
  [result interpretation](docs/evaluation/result-claims.md) 与
  [benchmark suite](docs/evaluation/benchmark-suite.md)。

## 示例和结果数据

仓库包含小型示例、benchmark 规格和归档结果数据。

```text
benchmarks/specs/smoke/        快速本地检查规格
benchmarks/specs/bench/        curated benchmark 规格
artifact/results/core_28/      28 个 benchmark 的归档结果数据
artifact/evidence/             可读结果表和分类说明
```

不重新运行 solver，直接检查归档结果：

```bash
artifact/scripts/check_expected.py \
  --expected artifact/expected/core_28.expected.json \
  --actual artifact/results/core_28/core_28.casewise.actual.json
```

生成 CSV 摘要：

```bash
artifact/scripts/make_tables.py \
  --results-json artifact/results/core_28/core_28.casewise.actual.json \
  --out-csv .tmp/procurator/artifact/core_28_summary.csv
```

## 仓库结构

```text
src/bin/procurator        CLI 入口
src/dslc/                 DSL parser、compiler、harness generation、workflow
src/p4b/source/           带 Procurator 后端的 P4B/p4c fork
benchmarks/specs/         Procurator .prop 规格
benchmarks/datasets/      规格使用的 P4 程序和表项
artifact/                 示例 workflow、expected profile、归档结果
docs/                     教程、CLI 参考、设计说明、agent skill
third_party/              第三方 provenance 和固定工具源码/运行时输入
tools/release/            源码树检查和发布辅助脚本
```

生成文件默认放在 `.tmp/procurator/`，或放在用户显式指定的输出目录。它们不是源码。
