# Procurator

[English](README.md) | [中文](README_zh.md)

Procurator is an open-source verifier for distributed, stateful P4 systems.

It reads a declarative `.prop` network specification, translates imported P4
programs with the pinned P4B/p4c backend, builds a distributed Boogie harness,
and runs Ultimate/GemCutter to find counterexamples or discharge bounded safety
obligations.

New here? Start with the [tutorial](docs/tutorial.md), then keep
[the CLI reference](docs/cli.md) open while running your own specs.

## Highlights

- Verifies systems described by P4 programs, table entries, topology, host
  traffic, environment assumptions, and global safety properties.
- Models distributed packet flow with hosts, links, node-local state, queues,
  and actor scheduling.
- Emits Boogie harnesses for concurrent or sequential execution.
- Uses the in-repository P4B/p4c fork for P4-local translation and the DSLC
  compiler for distributed harness generation.
- Runs Ultimate/GemCutter with checked toolchain and settings profiles.
- Preserves evidence for counterexamples: Boogie files, solver logs, witnesses,
  bounded replay records, and wraparound manifests.
- Includes runnable benchmarks plus archived result data under `artifact/`.

## Install

Use Linux or WSL for P4B-dependent and solver-heavy runs.

On a minimal Ubuntu 20.04/22.04 machine, install system packages first:

```bash
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  git ca-certificates curl wget unzip \
  python3 python3-venv \
  build-essential cmake pkg-config bison flex libfl-dev \
  libgc-dev libgmp-dev \
  libboost-dev libboost-iostreams-dev libboost-graph-dev \
  openjdk-21-jre-headless z3
```

Use a filesystem with several GB of free space for `src/p4b/source/build-host`
and `.tmp/procurator/`; P4B and Ultimate/GemCutter are not small.

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r src/dslc/requirements.txt
```

Build the P4B translator:

```bash
mkdir -p src/p4b/source/build-host
cd src/p4b/source/build-host
cmake -DP4C_USE_GOLD=OFF -DENABLE_GTESTS=OFF ..
cmake --build . --target p4c-translator -j"$(nproc)"
cd -
```

Install the pinned Ultimate/GemCutter runtime:

```bash
artifact/scripts/setup_gemcutter.sh
export ULTIMATE="$PWD/.tmp/procurator/toolchains/gemcutter/UGemCutter-linux/Ultimate"
```

## Quick start

Compile a NetChain spec to Boogie:

```bash
./src/bin/procurator compile \
  --spec benchmarks/specs/smoke/netchain_bug.prop \
  --out .tmp/procurator/examples/netchain_bug.bpl
```

Run a structural harness check:

```bash
./src/bin/procurator smoke \
  --bpl .tmp/procurator/examples/netchain_bug.bpl \
  --harness concurrent
```

Verify the NetChain wraparound example:

```bash
./src/bin/procurator verify \
  --spec benchmarks/specs/bench/netchain_wraparound_bug.prop \
  --ultimate "$ULTIMATE" \
  --toolchain ReachSafety.xml \
  --settings ReachSafety-32bit-GemCutter-internal.epf
```

`UNSAFE` means Procurator found a violating execution in the generated model.
`SAFE` means the selected model and bound passed. `TIMEOUT`, `UNKNOWN`, OOM,
toolchain errors, missing witnesses, and unaudited `SAFE` results are
inconclusive.

## CLI

`./src/bin/procurator` is the public command surface.

```text
procurator compile     Compile a .prop spec to Boogie or Promela.
procurator verify      Compile a .prop spec and run Ultimate/GemCutter.
procurator smoke       Check generated Boogie structure without a solver.
procurator wraparound  Run the explicit wraparound pipeline.
procurator ablation    Run symmetry, splitting, and slicing ablations.
```

See [docs/cli.md](docs/cli.md) for command parameters, execution effects,
Boogie generation, GemCutter invocation, and Ultimate profile selection.

By default, `procurator verify` uses `ReachSafety.xml` with
`ReachSafety-32bit-GemCutter-internal.epf`, the in-repository GemCutter profile
kept under `src/dslc/toolchain/ultimate/settings/gemcutter/base/`. Larger `ALL`,
8g, and witness profiles are available for runs that explicitly need them.

## Docs by goal

- Learn the DSL and syntax tree:
  [tutorial](docs/tutorial.md) and
  [DSL language notes](docs/design/dsl-language.md).
- Run Procurator:
  [CLI reference](docs/cli.md) and
  [troubleshooting](docs/troubleshooting/known-issues.md).
- Use agents to operate the tool:
  [agent skill](docs/agent/SKILL.md).
- Understand the implementation:
  [architecture](docs/design/architecture.md) and
  [wraparound certification](docs/design/wraparound-certification.md).
- Interpret archived results:
  [result interpretation](docs/evaluation/result-claims.md) and
  [benchmark suite](docs/evaluation/benchmark-suite.md).

## Examples and result data

The repository includes small examples, curated benchmark specs, and archived
result data.

```text
benchmarks/specs/smoke/        small specs for fast local checks
benchmarks/specs/bench/        curated benchmark specs
artifact/results/core_28/      archived 28-benchmark result dataset
artifact/evidence/             readable result tables and classification notes
```

Check the archived 28-benchmark result without rerunning the solver:

```bash
artifact/scripts/check_expected.py \
  --expected artifact/expected/core_28.expected.json \
  --actual artifact/results/core_28/core_28.casewise.actual.json
```

Generate a CSV summary:

```bash
artifact/scripts/make_tables.py \
  --results-json artifact/results/core_28/core_28.casewise.actual.json \
  --out-csv .tmp/procurator/artifact/core_28_summary.csv
```

## Repository layout

```text
src/bin/procurator        CLI entrypoint
src/dslc/                 DSL parser, compiler, harness generation, workflows
src/p4b/source/           pinned P4B/p4c fork with the Procurator backend
benchmarks/specs/         Procurator .prop specifications
benchmarks/datasets/      P4 programs and table entries used by specs
artifact/                 examples, expected profiles, archived results
docs/                     tutorial, CLI reference, design notes, agent skill
third_party/              third-party provenance and pinned tool sources
tools/release/            source-tree checks and packaging helpers
```

Generated files belong under `.tmp/procurator/` or an explicit output
directory. They are not source.
