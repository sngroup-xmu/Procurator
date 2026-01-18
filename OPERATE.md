
## 工具链操作手册（构建 / 增量构建 / 运行）

> 目标：回答你现在最关心的两个问题：
>
> - **(A) 端到端怎么跑通**：DSL → (P4B) Boogie → 并发 harness → Ultimate/GemCutter
> - **(B) 改源码后去哪里做增量构建**：Ultimate / P4B-Translator / DSL 编译器分别怎么最省时重建
>
> 注：下面命令默认你在 **仓库根目录**运行，并尽量使用仓库相对路径（避免 `/mnt/<drive>` 上的 IO 过慢/不稳定）。

### 0) 产物位置（你已经 build 成功）

- **Ultimate/GemCutter CLI（推荐直接用仓库内置）**：`UGemCutter-linux/Ultimate`
- **Ultimate CLI 产品目录（若你从源码构建）**：`ultimate/trunk/source/BA_SiteRepository/target/products/CLI-E4/linux/gtk/x86_64/Ultimate`
- **P4B-Translator Boogie 后端可执行**：`P4B-Translator/build-host/p4c-translator`（软链接到 `P4B-Translator/build-host/backends/verify/p4c-translator`）
- **DSL→Boogie 最小 E2E spec**：`Procurator/argo/code/spec/test/boogie_smoke.prop`

### 1) 端到端：DSL → Boogie → GemCutter（建议最小 smoke 路径）

#### 1.1 构建/更新 P4B-Translator（P4→Boogie）

```bash
cd P4B-Translator
mkdir -p build-host
cd build-host
cmake ..
cmake --build . --target p4c-translator -j"$(nproc)"

# 若遇到 ccache 权限错误（/run/user/0/...），禁用 ccache 再编译
CCACHE_DISABLE=1 cmake --build . --target p4c-translator -j"$(nproc)"
```

#### 1.2 准备 DSL 编译器 Python 环境（只需一次）

```bash
cd /root/p4-verify
python3 -m venv .venv
.venv/bin/python -m pip install -r Procurator/argo/code/spec/prop_compile/requirements.txt
```

#### 1.2.1 DSL 语法参考（最小示例 + 完整示例）

最小可跑（单节点 + 全局断言）：

```prop
import s1 from "/abs/path/to/program.p4" entries "/abs/path/to/commands.txt";

topology {
  // 单节点不需要 link
}

node s1 {
  external_input = true;
  assume {
    hdr.ipv4.dstAddr == 167772161; // 10.0.0.1
  };
}

global {
  queue_capacity = 1;
  assert {
    s1_counter_reg[0] >= 0;
  };
}
```

完整示例（多节点 + host + env + symmetry + 断言/假设）：

```prop
import s1 from "/abs/path/to/p4a.p4" entries "/abs/path/to/commands_1.txt";
import s2 from "/abs/path/to/p4a.p4" entries "/abs/path/to/commands_2.txt";

topology {
  link s1 -> s2 ALL;
}

node s1 {
  external_input = true;
  // 节点局部约束（每次外部注入生效）
  assume {
    hdr.ethernet.etherType == 2048;
    hdr.ipv4.dstAddr == 167772162; // 10.0.0.2
  };
  // 节点局部断言（每次 pass 后检查）
  assert {
    s1_sequence_reg[0] >= 0;
  };
  // env: 注入时的自定义逻辑（可写赋值/if/assume/assert）
  env {
    // 例：强制某个字段为确定值
    hdr.nc_hdr.op = 12;
  };
}

node s2 {
}

host h1 {
  connect s1;
  assume {
    // Host 侧注入的额外约束
    hdr.ipv4.srcAddr == 167772161;
  };
}

global {
  queue_capacity = 1;
  env_thread = false;
  host_eager = true;
  symmetry(s1, s2);
  assert {
    s1_sequence_reg[0] >= s2_sequence_reg[0];
  };
}
```

要点：
- `assume { ...; }` / `assert { ...; }` 中每条语句用 `;` 分隔。
- 数字段路径支持 `hdr.overlay.0.swip`（点数字段）与 `reg[0]`（数组下标）。
- `external_input = true` 表示该节点接受外部输入（Env 注入）。
- `env { ... }` 用于自定义注入时的赋值/分支/约束。
- `host_eager = true` 让 host 每次循环都尝试注入（减少空转路径，便于复现 bug）。

#### 1.3 DSL → 并发 Boogie（会调用 host `p4c-translator` 生成每个节点 `.bpl` 并前缀化 + harness）

```bash
mkdir -p .tmp/dslc
PYTHONPATH=. .venv/bin/python -m dslc.compiler \
  --backend boogie \
  --spec Procurator/argo/code/spec/test/boogie_smoke.prop \
  --out .tmp/dslc/boogie_smoke.bpl \
  --p4b-bin P4B-Translator/build-host/p4c-translator \
  --work-dir .tmp/dslc/boogie_smoke.work
```

#### 1.3.1 Gecko（Tofino JSON）Boogie 运行（包含手动 ENV 约束）

Gecko 需要手动约束输入包（例如 `ether_type=0x5555`），使用 DSL 的 `env { ... }`：

```bash
mkdir -p .tmp/gecko_run
PYTHONPATH=. .venv/bin/python -m dslc.compiler \
  --backend boogie \
  --spec Procurator/argo/code/spec/test/gecko.prop \
  --out .tmp/gecko_run/gecko.bpl \
  --p4b-bin P4B-Translator/build-host/p4c-translator \
  --work-dir .tmp/gecko_run/work \
  --no-prune
```

> 说明：Gecko 的 JSON IR 中存在大量 Tofino 特定 metadata，当前 slicing/pruning 仍可能过度裁剪。
> 若要验证语义正确性，建议先 `--no-prune`，待剪枝稳定后再打开。若采用 host 输入建模，
> 建议在 `global` 中设置 `env_thread = false` 以避免 EnvThread 造成重复输入，并用 `host_eager = true`
> 触发稳定的 Host 注入序列。

#### 1.4 GemCutter 结构 smoke（不跑 Ultimate，仅检查 fork/atomic/ULTIMATE.start）

```bash
PYTHONPATH=. .venv/bin/python Procurator/argo/code/spec/prop_compile/gemcutter_smoke.py \
  --bpl .tmp/dslc/boogie_smoke.bpl
```

#### 1.5 真跑 Ultimate/GemCutter（运行 zip 中的 Ultimate）

直接运行仓库内置的 `UGemCutter-linux/Ultimate`（推荐）：

```bash
UGemCutter-linux/Ultimate --version
UGemCutter-linux/Ultimate \
  -tc Procurator/argo/code/spec/config/ReachSafety-Witness.xml \
  -s Procurator/argo/code/spec/config/ReachSafety-32bit-GemCutter-ALL-witness.epf \
  -i .tmp/dslc/boogie_smoke.bpl \
  > .tmp/dslc/boogie_smoke.gemcutter.log 2>&1

grep -nE 'RESULT|AllSpecificationsHoldResult|proved your program|incorrect|Exception' \
  .tmp/dslc/boogie_smoke.gemcutter.log | tail -n 50
```

Gecko 对应的运行示例（使用 Internal SMTInterpol 设置）：

```bash
env HOME="$PWD/.tmp/ultimate_home" \
JAVA_TOOL_OPTIONS="-Duser.home=$PWD/.tmp/ultimate_home" \
UGemCutter-linux/Ultimate \
  -data .tmp/ultimate_ws \
  -tc Procurator/argo/code/spec/config/ReachSafety-Witness.xml \
  -s Procurator/argo/code/spec/config/ReachSafety-32bit-GemCutter-internal-witness.epf \
  -i .tmp/gecko_run/gecko.bpl \
  > .tmp/gecko_run/gecko.gemcutter.log 2>&1

rg -n "RESULT|AllSpecificationsHoldResult|Exception|TypeError" .tmp/gecko_run/gecko.gemcutter.log | tail -n 50
```

补充：对照 prune vs no-prune（slicing+env prune 开关）时，建议用 `run_gemcutter.py` 的 `--out/--work-dir/--log`
指定不同路径，避免覆盖同一份 `.bpl/.log/.graphml`。

#### 1.6 故障排查与“真证明”确认

> 结论先说清楚：**你的命令本身没问题**，失败/成功的差异通常来自
> **(a) 生成的 `.bpl` 是否是最新**、**(b) Boogie 并发语法与 modifies 约束是否满足 Ultimate 的检查**、以及 **(c) 程序里是否真的有可验证的 specification（assert）**。

- **(1) 先重新生成 `.bpl`**

  修了 `dslc/backends/boogie.py` 或 `.prop` 后，如果不重新跑 1.3，还是用旧的 `boogie_smoke.bpl`，Ultimate 看到的仍然是旧问题。

- **(2) 典型失败 ①：Syntax error（fork 语法）**

  最早遇到的是类似：
  - `SyntaxErrorResult [Line: 588]: Incorrect Syntax`

  原因：GemCutter/Ultimate 的并发 Boogie 语法需要 **显式 thread id**：
  - ✅ `fork 0 EnvThread();`
  - ✅ `fork 1 s1Thread();`
  - ❌ `fork EnvThread();`（会直接语法错误）

  修复：更新 Boogie 生成器（入口：`dslc/backends/boogie.py`；实现主体：`dslc/backends/boogie_backend.py` / `dslc/backends/boogie_harness.py`）后**重新生成** `.bpl`。

- **(3) 典型失败 ②：TypeError（modifies 不完备 / fork 的 modifies 传递性）**

  后来遇到的是类似：
  - `Global variable XXX modified in procedure s1Thread but not contained in procedures modifies clause.`
  - `Procedure s1Thread may modify XXX procedure ULTIMATE.start must not modify XXX. Fork ... Modifies not transitive`

  原因：Ultimate 的 Boogie 类型检查对 `modifies` 很严格：
  - `havoc` 也是写操作，所以 `s1Thread` 的 `modifies` 里必须包含被 havoc 的变量
  - `fork` 在 modifies 检查上**近似当成调用**：`ULTIMATE.start` 的 `modifies` 需要保守覆盖 fork 出去的线程可能写到的全局变量

  修复：同样是更新 generator + **重新生成** `.bpl`。

```bash
UGemCutter-linux/Ultimate \
  -tc Procurator/argo/code/spec/config/ReachSafety-Witness.xml \
  -s Procurator/argo/code/spec/config/ReachSafety-32bit-GemCutter-ALL-witness.epf \
  -i .tmp/dslc/boogie_smoke.bpl \
  > /tmp/boogie_smoke_gemcutter.log 2>&1

grep -nE 'SyntaxErrorResult|TypeErrorResult|AllSpecificationsHoldResult|program does not contain any specification|RESULT:' \
  /tmp/boogie_smoke_gemcutter.log | tail -n 80
```

---

### 2) Ultimate（源码）改动后：去哪里做“增量构建”

#### 2.1 你改源码的位置

- **Java/插件源码**：`ultimate/trunk/source/`
- **Maven 聚合工程入口**：`ultimate/trunk/source/BA_MavenParentUltimate/`
- **打包脚本**：`ultimate/releaseScripts/default/`

#### 2.2 增量构建（只重编译变化的模块）

> 关键点：Tycho 4.0.9 要求 **Maven ≥ 3.9**。apt 的 Maven 3.8.7 会直接失败。
> 我们落地了一个本地 Maven 3.9.12

```bash
# 增量（推荐）：不 clean，Maven 会复用已编译产物
mvn -T 1C install -Pmaterialize

# 如果你只改了少量模块：用 -pl 精确重建（示例）
# mvn -T 1C -pl :de.uni_freiburg.informatik.ultimate.boogie.preprocessor -am install -Pmaterialize
```

#### 2.3 只重打 GemCutter 的 zip（不重跑整套 makeFresh）

```bash
cd ultimate/releaseScripts/default

# 先确保打包工具齐全
sudo apt-get install -y zip unzip

# 只打 GemCutter（makeFresh.sh 里就是这么调用的）
bash makeZip.sh GemCutter linux \
  AutomizerCInline_IcfgBuilder_WitnessPrinter.xml \
  NONE \
  AutomizerCInline_IcfgBuilder.xml \
  AutomizerCInline_IcfgBuilder_WitnessPrinter.xml \
  NONE \
  NONE

ls -lh UltimateGemCutter-linux.zip
```

#### 2.4 全量重建（最慢，但最稳）

```bash
cd ultimate/releaseScripts/default
bash makeFresh.sh
```

---

### 3) P4B-Translator 改动后：去哪里做“增量构建”

- **源码位置**：`P4B-Translator/`
- **增量编译目录（建议固定用一个）**：`P4B-Translator/build-host/`

```bash
cd P4B-Translator/build-host

# 只要 CMakeLists.txt 没大改，一般直接 build 即可
cmake --build . --target p4c-translator -j"$(nproc)"

# 如果你改了 CMake 结构/选项，先 re-configure 再 build
# cmake .. && cmake --build . --target p4c-translator -j"$(nproc)"
```

---

### 4) DSL 编译器（Python）改动后：去哪里做“增量构建”

- **源码位置（统一入口）**：`dslc/`
- **不需要 build**：改完直接用 venv 跑即可；建议跑单测回归：

```bash
cd /root/p4-verify
.venv/bin/python -m unittest -v dslc.tests.test_boogie_backend_smoke
```

### 6) DSL 里的 env / host 建模（现状）

- **node.env { ... }**：用于外部输入注入时的字段约束/赋值（例如 Gecko 的 `ether_type=0x5555`）。
- **host { connect <node>; env { ... } }**：显式 Host actor，支持发送/接收回路与 host 侧断言；发送包会注入到连接的节点。

---

### 5) 常见坑（刚刚踩过的）

- **Ultimate build 报 “Tycho requires Maven 3.9.0”**：用本地 Maven 3.9.9 跑（见 2.2），不要用 apt 的 3.8.7。
- **makeFresh.sh 最后打包失败：`zip: command not found`**：`sudo apt-get install -y zip unzip`。
- **P4→Boogie 翻译报 `no include path ... core.p4/v1model.p4`**：调用 `p4c-translator` 时需要 `-I P4B-Translator/p4include`（DSL Boogie backend 已自动探测并注入）。

---
