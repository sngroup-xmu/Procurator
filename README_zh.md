# Procurator：分布式状态化 P4 验证

Procurator 是一个用于验证分布式、状态化 P4 程序的研究原型。它将 DSL 规格编译为 Boogie，
生成并发 harness，并交给 Ultimate/GemCutter 做安全性验证。默认流程：

DSL spec (.prop) -> Boogie (.bpl) -> Ultimate/GemCutter -> witness/trace

本仓库包含：
- P4B-Translator（P4 -> Boogie）
- Ultimate/GemCutter（并发验证器）
- DSL 编译器 + harness 生成器

## 目录结构

- `Procurator/argo/code/spec`：DSL 规格与编译入口
- `Procurator/argo/code/dataset`：P4 程序与控制面 entries
- `P4B-Translator`：P4 -> Boogie 翻译器（基于 p4c）
- `ultimate/releaseScripts/default/UGemCutter-linux`：Ultimate CLI 二进制
- `UGemCutter-linux`：备用 Ultimate 包（同一套二进制）
- `.tmp/dslc`：运行时生成的 Boogie / 日志 / witness

## 系统依赖

Ubuntu 24.04 (WSL) + Java 21。建议直接使用仓库自带的 Ultimate 包与自带的 Z3。

```bash
sudo apt-get update
sudo apt-get install -y \
  cmake g++ git automake libtool libgc-dev bison flex libfl-dev libgmp-dev \
  libboost-dev libboost-iostreams-dev libboost-graph-dev llvm pkg-config \
  python3 python3-pip python3-ply python3-scapy \
  protobuf-compiler libprotobuf-dev \
  openjdk-21-jre-headless
```

## Python 环境（DSL 编译器）

```bash
python3 -m venv /mnt/e/p4-verify/.venv
/mnt/e/p4-verify/.venv/bin/python -m pip install \
  -r /mnt/e/p4-verify/Procurator/argo/code/spec/prop_compile/requirements.txt
```

## 构建 P4B-Translator（P4 -> Boogie）

`P4B-Translator` 里不包含 gtest 源码，且 WSL 下 gold linker 可能崩溃，
建议禁用 gtest 与 gold。

```bash
mkdir -p /mnt/e/p4-verify/P4B-Translator/build-host
cd /mnt/e/p4-verify/P4B-Translator/build-host
cmake -DP4C_USE_GOLD=OFF -DENABLE_GTESTS=OFF ..
cmake --build . --target p4c-translator -j"$(nproc)"
```

可执行文件路径：

```
/mnt/e/p4-verify/P4B-Translator/build-host/backends/verify/p4c-translator
```

## Ultimate/GemCutter 配置（Boogie 后端）

Ultimate 需要 Java 21。Z3 在 Ultimate 目录内。

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=/mnt/e/p4-verify/ultimate/releaseScripts/default/UGemCutter-linux:$JAVA_HOME/bin:$PATH
```

Ultimate 可执行文件：

```
/mnt/e/p4-verify/ultimate/releaseScripts/default/UGemCutter-linux/Ultimate
```

## Boogie 用法

1) DSL -> Boogie：

```bash
PYTHONPATH=/mnt/e/p4-verify /mnt/e/p4-verify/.venv/bin/python -m dslc.compiler \
  --backend boogie \
  --spec /mnt/e/p4-verify/Procurator/argo/code/spec/test/boogie_smoke.prop \
  --out /mnt/e/p4-verify/.tmp/dslc/boogie_smoke.bpl \
  --p4b-bin /mnt/e/p4-verify/P4B-Translator/build-host/backends/verify/p4c-translator \
  --work-dir /mnt/e/p4-verify/.tmp/dslc/boogie_smoke.work
```

2) Ultimate/GemCutter 运行 Boogie：

```bash
/mnt/e/p4-verify/ultimate/releaseScripts/default/UGemCutter-linux/Ultimate \
  -tc /mnt/e/p4-verify/Procurator/argo/code/spec/config/ReachSafety-Witness.xml \
  -s  /mnt/e/p4-verify/Procurator/argo/code/spec/config/ReachSafety-32bit-GemCutter-internal-witness.epf \
  -i  /mnt/e/p4-verify/.tmp/dslc/boogie_smoke.bpl
```

输出在 `.tmp/dslc/`：
- `*.bpl`：Boogie 程序
- `*.gemcutter.log`：Ultimate 日志
- `*.bpl-witness.graphml`：反例 witness（若 UNSAFE）

## DSL 规格怎么写

`.prop` 文件由四个核心 block 组成：`import`、`topology`、`node/host`、`global`。

最小示例：

```prop
import s1 from "/abs/path/to/program.p4" entries "/abs/path/to/commands.txt";

topology {
  // 单节点可不写 link
}

node s1 {
  external_input = true;
  assume { hdr.ipv4.dstAddr == 167772161; };
}

global {
  queue_capacity = 1;
  assert { s1_counter_reg[0] >= 0; };
}
```

完整示例（多节点 + host + env + symmetry）：

```prop
import s1 from "/abs/path/to/p4a.p4" entries "/abs/path/to/commands_1.txt";
import s2 from "/abs/path/to/p4a.p4" entries "/abs/path/to/commands_2.txt";

topology {
  link s1 -> s2 ALL;
}

node s1 {
  external_input = true;
  assume {
    hdr.ethernet.etherType == 2048;
    hdr.ipv4.dstAddr == 167772162;
  };
  assert { s1_sequence_reg[0] >= 0; };
  env {
    // 注入时自定义逻辑（赋值/if/assume/assert）
    hdr.nc_hdr.op = 12;
  };
}

node s2 {}

host h1 {
  connect s1;
  assume { hdr.ipv4.srcAddr == 167772161; };
}

global {
  queue_capacity = 1;
  env_thread = false;
  host_eager = true;
  symmetry(s1, s2);
  assert { s1_sequence_reg_0[0] >= s2_sequence_reg_0[0]; };
}
```

参数含义：

- `import <alias> from "<p4_path>" [entries "<commands.txt>"];`
  - `alias` 是节点名；`entries` 可选，指向控制面命令文件。
- `topology { link <src> -> <dst> <port|ALL>; }`
  - `port` 为具体 egress 端口，或 `ALL` 表示任意端口。
- `node <alias> { ... }`
  - `external_input = true|false`：是否允许外部输入注入。
  - `assume { ...; }`：外部输入的字段约束。
  - `assert { ...; }`：节点局部断言（每次 pass 后检查）。
  - `env { ... }`：注入时自定义逻辑（赋值/分支/约束）。
- `host <name> { connect <node>; ... }`
  - `connect` 指定 Host 注入到的节点。
  - `assume { ...; }` 为 Host 侧约束。
- `global { ... }`
  - `queue_capacity = <int>`：邮箱容量（越小越容易求解）。
  - `env_thread = false`：关闭自动 EnvThread 注入。
  - `host_eager = true`：每步都尝试 Host 注入。
  - `symmetry(n1, n2, ...)`：基于 inbox 计数的对称性约束。
  - `assert { ...; }`：全局断言（每次 pass 后检查）。
  - `int name = <int>;`：定义辅助整数状态。

表达式说明：

- `assume/assert/env` 块内每条语句必须以 `;` 结束。
- 字段访问支持 `hdr.foo.bar`、`hdr.overlay.0.swip`、`reg[0]`。
- 布尔运算使用 `&&`、`||`、`!` 与比较运算符。
- 如果单条语句内有 `||`，建议整体加括号避免解析歧义。

运行选项：

- `run_gemcutter.py --env max`：忽略 `assume`，使用完全非确定输入。
- `--no-slicing`：关闭 slicing。Gecko/DistCache 在本仓库默认需要关闭。

## Benchmark 运行（Max-Env）

先设置环境：

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=/mnt/e/p4-verify/ultimate/releaseScripts/default/UGemCutter-linux:$JAVA_HOME/bin:$PATH
export PYTHONPATH=/mnt/e/p4-verify
```

ATP：

```bash
/mnt/e/p4-verify/.venv/bin/python \
  /mnt/e/p4-verify/Procurator/argo/code/spec/prop_compile/run_gemcutter.py \
  --spec /mnt/e/p4-verify/Procurator/argo/code/spec/bench/atp_bug.prop \
  --p4b-bin /mnt/e/p4-verify/P4B-Translator/build-host/backends/verify/p4c-translator \
  --ultimate /mnt/e/p4-verify/ultimate/releaseScripts/default/UGemCutter-linux/Ultimate \
  --env max \
  --toolchain /mnt/e/p4-verify/Procurator/argo/code/spec/config/ReachSafety-Witness.xml \
  --settings /mnt/e/p4-verify/Procurator/argo/code/spec/config/ReachSafety-32bit-GemCutter-internal-witness.epf
```

NetChain：

```bash
/mnt/e/p4-verify/.venv/bin/python \
  /mnt/e/p4-verify/Procurator/argo/code/spec/prop_compile/run_gemcutter.py \
  --spec /mnt/e/p4-verify/Procurator/argo/code/spec/test/netchain_bug.prop \
  --p4b-bin /mnt/e/p4-verify/P4B-Translator/build-host/backends/verify/p4c-translator \
  --ultimate /mnt/e/p4-verify/ultimate/releaseScripts/default/UGemCutter-linux/Ultimate \
  --env max \
  --toolchain /mnt/e/p4-verify/Procurator/argo/code/spec/config/ReachSafety-Witness.xml \
  --settings /mnt/e/p4-verify/Procurator/argo/code/spec/config/ReachSafety-32bit-GemCutter-internal-witness.epf
```

P4XOS：

```bash
/mnt/e/p4-verify/.venv/bin/python \
  /mnt/e/p4-verify/Procurator/argo/code/spec/prop_compile/run_gemcutter.py \
  --spec /mnt/e/p4-verify/Procurator/argo/code/spec/bench/p4xos_bug.prop \
  --p4b-bin /mnt/e/p4-verify/P4B-Translator/build-host/backends/verify/p4c-translator \
  --ultimate /mnt/e/p4-verify/ultimate/releaseScripts/default/UGemCutter-linux/Ultimate \
  --env max \
  --toolchain /mnt/e/p4-verify/Procurator/argo/code/spec/config/ReachSafety-Witness.xml \
  --settings /mnt/e/p4-verify/Procurator/argo/code/spec/config/ReachSafety-32bit-GemCutter-internal-witness.epf
```

DistCache（建议 `--no-slicing`）：

```bash
/mnt/e/p4-verify/.venv/bin/python \
  /mnt/e/p4-verify/Procurator/argo/code/spec/prop_compile/run_gemcutter.py \
  --spec /mnt/e/p4-verify/Procurator/argo/code/spec/bench/distcache_bug.prop \
  --p4b-bin /mnt/e/p4-verify/P4B-Translator/build-host/backends/verify/p4c-translator \
  --ultimate /mnt/e/p4-verify/ultimate/releaseScripts/default/UGemCutter-linux/Ultimate \
  --env max \
  --no-slicing \
  --toolchain /mnt/e/p4-verify/Procurator/argo/code/spec/config/ReachSafety-Witness.xml \
  --settings /mnt/e/p4-verify/Procurator/argo/code/spec/config/ReachSafety-32bit-GemCutter-internal-witness.epf
```

Gecko（Tofino JSON，建议 `--no-slicing`）：

```bash
/mnt/e/p4-verify/.venv/bin/python \
  /mnt/e/p4-verify/Procurator/argo/code/spec/prop_compile/run_gemcutter.py \
  --spec /mnt/e/p4-verify/Procurator/argo/code/spec/bench/gecko_bug1_timer_loss.prop \
  --p4b-bin /mnt/e/p4-verify/P4B-Translator/build-host/backends/verify/p4c-translator \
  --ultimate /mnt/e/p4-verify/ultimate/releaseScripts/default/UGemCutter-linux/Ultimate \
  --env max \
  --no-slicing \
  --toolchain /mnt/e/p4-verify/Procurator/argo/code/spec/config/ReachSafety-Witness.xml \
  --settings /mnt/e/p4-verify/Procurator/argo/code/spec/config/ReachSafety-32bit-GemCutter-internal-witness.epf
```

## 常见问题

- Java 版本不匹配（class file version 65/69）：
  - 使用 Java 21，并确保 `JAVA_HOME` 正确。
- 找不到 Z3：
  - 把 Ultimate 目录加到 `PATH`：
    `/mnt/e/p4-verify/ultimate/releaseScripts/default/UGemCutter-linux`
- gold linker 崩溃：
  - 使用 `-DP4C_USE_GOLD=OFF` 重新配置 P4B-Translator。
- DistCache 的 Boogie 字段缺失：
  - 用 `--no-slicing` 运行。
