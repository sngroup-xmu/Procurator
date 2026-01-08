# Procurator: Distributed Stateful P4 Verification

Procurator is a research prototype for verifying distributed, stateful P4
programs. It compiles a DSL spec into Boogie, generates a concurrent harness,
and discharges safety properties with Ultimate/GemCutter. The default flow is:

DSL spec (.prop) -> Boogie (.bpl) -> Ultimate/GemCutter -> witness/trace

This repository vendors:
- P4B-Translator (P4 -> Boogie)
- Ultimate/GemCutter (concurrent verifier)
- A DSL compiler + harness generator

## Repository Layout

- `Procurator/argo/code/spec`: DSL specs and compiler entrypoints
- `Procurator/argo/code/dataset`: P4 programs and control-plane entries
- `P4B-Translator`: P4 -> Boogie translator (p4c-based)
- `ultimate/releaseScripts/default/UGemCutter-linux`: Ultimate CLI binary
- `UGemCutter-linux`: alternate Ultimate bundle (same binaries)
- `.tmp/dslc`: generated Boogie + logs + witnesses (created at runtime)

## System Requirements

Ubuntu 24.04 (WSL) + Java 21. The fastest path is to use the bundled
Ultimate binary and the bundled Z3 inside that folder.

Recommended packages:

```bash
sudo apt-get update
sudo apt-get install -y \
  cmake g++ git automake libtool libgc-dev bison flex libfl-dev libgmp-dev \
  libboost-dev libboost-iostreams-dev libboost-graph-dev llvm pkg-config \
  python3 python3-pip python3-ply python3-scapy \
  protobuf-compiler libprotobuf-dev \
  openjdk-21-jre-headless
```

## Python Environment (DSL Compiler)

```bash
python3 -m venv /mnt/e/p4-verify/.venv
/mnt/e/p4-verify/.venv/bin/python -m pip install \
  -r /mnt/e/p4-verify/Procurator/argo/code/spec/prop_compile/requirements.txt
```

## Build P4B-Translator (P4 -> Boogie)

The p4c tree in `P4B-Translator` does not ship with gtest sources.
Disable gtests and disable the gold linker to avoid linker issues on WSL.

```bash
mkdir -p /mnt/e/p4-verify/P4B-Translator/build-host
cd /mnt/e/p4-verify/P4B-Translator/build-host
cmake -DP4C_USE_GOLD=OFF -DENABLE_GTESTS=OFF ..
cmake --build . --target p4c-translator -j"$(nproc)"
```

Binary path:

```
/mnt/e/p4-verify/P4B-Translator/build-host/backends/verify/p4c-translator
```

## Ultimate/GemCutter Setup (Boogie Backend)

Ultimate requires Java 21. The bundled Z3 is inside the Ultimate folder.

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=/mnt/e/p4-verify/ultimate/releaseScripts/default/UGemCutter-linux:$JAVA_HOME/bin:$PATH
```

Ultimate executable:

```
/mnt/e/p4-verify/ultimate/releaseScripts/default/UGemCutter-linux/Ultimate
```

## Boogie Usage

1) Compile DSL -> Boogie:

```bash
PYTHONPATH=/mnt/e/p4-verify /mnt/e/p4-verify/.venv/bin/python -m dslc.compiler \
  --backend boogie \
  --spec /mnt/e/p4-verify/Procurator/argo/code/spec/test/boogie_smoke.prop \
  --out /mnt/e/p4-verify/.tmp/dslc/boogie_smoke.bpl \
  --p4b-bin /mnt/e/p4-verify/P4B-Translator/build-host/backends/verify/p4c-translator \
  --work-dir /mnt/e/p4-verify/.tmp/dslc/boogie_smoke.work
```

2) Run Ultimate on the Boogie program:

```bash
/mnt/e/p4-verify/ultimate/releaseScripts/default/UGemCutter-linux/Ultimate \
  -tc /mnt/e/p4-verify/Procurator/argo/code/spec/config/ReachSafety-Witness.xml \
  -s  /mnt/e/p4-verify/Procurator/argo/code/spec/config/ReachSafety-32bit-GemCutter-internal-witness.epf \
  -i  /mnt/e/p4-verify/.tmp/dslc/boogie_smoke.bpl
```

Outputs go to `.tmp/dslc/`:
- `*.bpl`: generated Boogie
- `*.gemcutter.log`: Ultimate log
- `*.bpl-witness.graphml`: counterexample witness (if UNSAFE)

## Spec Language (DSL)

A spec file (`*.prop`) glues P4 programs, topology, environment, and safety
properties. The compiler lives in `dslc` and is used by `run_gemcutter.py`.

Minimal skeleton:

```prop
import s1 from "/abs/path/to/program.p4" entries "/abs/path/to/commands.txt";

topology {
  // link s1 -> s2 ALL;
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

Full example (multi-node + host + env + symmetry):

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
    // custom injection logic (assign/if/assume/assert allowed)
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
  assert { s1_sequence_reg[0] >= s2_sequence_reg[0]; };
}
```

Block and parameter reference:

- `import <alias> from "<p4_path>" [entries "<commands.txt>"];`
  - `alias` becomes the node name used elsewhere.
  - `entries` is optional and points to control-plane commands.
- `topology { link <src> -> <dst> <port|ALL>; }`
  - `port` is a concrete egress port, or `ALL` for any port.
- `node <alias> { ... }`
  - `external_input = true|false` enables environment injection for this node.
  - `assume { ...; }` constrains fields for external inputs.
  - `assert { ...; }` local safety checks, evaluated after each pass.
  - `env { ... }` injection-time logic (assign/if/assume/assert).
- `host <name> { connect <node>; ... }`
  - `connect` selects the node that receives host-injected packets.
  - `assume { ...; }` adds host-side constraints (same syntax as node).
- `global { ... }`
  - `queue_capacity = <int>` mailbox capacity (small values reduce state space).
  - `env_thread = false` disables automatic EnvThread injection.
  - `host_eager = true` makes host injection attempt every step.
  - `symmetry(n1, n2, ...)` adds symmetry breaking on inbox counts.
  - `assert { ...; }` global safety checks, evaluated after each pass.
  - `int name = <int>;` declares auxiliary integer state for the harness.

Expression notes:

- Use `;` to terminate each statement inside `assume`/`assert`/`env`.
- Field access supports `hdr.foo.bar`, `hdr.overlay.0.swip`, and `reg[0]`.
- Boolean ops use `&&`, `||`, `!`, and comparisons (`==`, `!=`, `<`, `<=`, `>`, `>=`).
- If a single statement uses `||`, wrap it in parentheses to avoid parser ambiguity.

Runtime knobs:

- `run_gemcutter.py --env max` ignores `assume` on external inputs and uses
  fully nondeterministic packets.
- `--no-slicing` disables P4 slicing; required for Gecko/DistCache in this repo.

## Benchmark Runs (Max-Env)

All runs below enable witness generation and use the internal SMTInterpol
settings from `ReachSafety-32bit-GemCutter-internal-witness.epf`.

Set environment once:

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=/mnt/e/p4-verify/ultimate/releaseScripts/default/UGemCutter-linux:$JAVA_HOME/bin:$PATH
export PYTHONPATH=/mnt/e/p4-verify
```

ATP:

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

NetChain:

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

P4XOS:

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

DistCache (use --no-slicing to avoid missing header fields):

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

Gecko (Tofino JSON, use --no-slicing):

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

## Troubleshooting

- Java version errors (class file version 65/69):
  - Use Java 21 (`openjdk-21-jre-headless`) and ensure `JAVA_HOME` points to it.
- Z3 not found:
  - Add Ultimate folder to `PATH`:
    `/mnt/e/p4-verify/ultimate/releaseScripts/default/UGemCutter-linux`
- Gold linker crashes:
  - Configure P4B-Translator with `-DP4C_USE_GOLD=OFF`.
- Undeclared identifiers in Boogie for DistCache:
  - Re-run with `--no-slicing`.
