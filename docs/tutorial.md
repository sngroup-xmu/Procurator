# Procurator Tutorial

This tutorial shows how to read a Procurator specification, compile it to
Boogie, and verify NetChain with Ultimate/GemCutter.

## Concepts

Procurator separates the system description from the verification backend.

```text
.prop specification
  imports P4 programs and table entries
  declares topology
  declares host traffic and node assumptions
  declares global safety properties
        |
        v
P4B translation
  parses P4
  lowers parser/control/table/register behavior
  emits Boogie procedures and metadata
        |
        v
DSLC harness
  wires nodes and hosts
  models queues and actor scheduling
  applies environment assumptions
  emits global assertions
        |
        v
Ultimate/GemCutter
  checks reachability and safety
  emits logs and witnesses for counterexamples
```

The public command surface is always `./src/bin/procurator`.

## Specification syntax tree

A `.prop` file has one top-level tree.

```text
spec
  import*
    alias
    P4 or Boogie path
    optional table-entry path
  topology
    link*
      source node
      destination node
      port or ALL
  node* | host*
    statements
      declarations
      assignments
      assumptions
      assertions
      environment blocks
      conditionals
  global
    queue and scheduler settings
    assumptions
    assertions
    reachability declarations
    symmetry declarations
```

The grammar entry point is:

```text
start: import_section topology_section (node_section | host_section)* global_section
```

The main section forms are:

```text
import s1 from "../../datasets/Netchain/netchain_16.p4"
  entries "../../datasets/Netchain/commands_1.txt";

topology {
  link s1 -> s2 ALL;
}

host h1 {
  connect s1;
  env {
    hdr.ipv4.valid = true;
  }
}

node s1 {
  external_input = false;
}

global {
  queue_capacity = 1;
  deterministic_scheduler = true;

  assume {
    s1_find_index.hit == true;
  };

  assert {
    s1_sequence_reg[0] >= s2_sequence_reg[0];
  };
}
```

Expressions support integer and boolean values, dotted P4/Boogie names,
register indices, bit slices, arithmetic, comparisons, `&&`, `||`, and `!`.

## Install runtime dependencies

Use Linux or WSL for solver-heavy runs.

On a minimal Ubuntu 20.04/22.04 machine, install system packages first:

```bash
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  git ca-certificates curl wget unzip \
  python3 python3-venv \
  build-essential cmake pkg-config bison flex libfl-dev \
  libgc-dev libgmp-dev \
  libboost-dev libboost-iostreams-dev libboost-graph-dev \
  openjdk-21-jre-headless
```

Use a filesystem with several GB of free space for `src/p4b/source/build-host`
and `.tmp/procurator/`.

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r src/dslc/requirements.txt
```

Build P4B:

```bash
mkdir -p src/p4b/source/build-host
cd src/p4b/source/build-host
cmake -DP4C_USE_GOLD=OFF -DENABLE_GTESTS=OFF ..
cmake --build . --target p4c-translator -j"$(nproc)"
cd -
```

Install Ultimate/GemCutter:

```bash
artifact/scripts/setup_gemcutter.sh
export ULTIMATE="$PWD/.tmp/procurator/toolchains/gemcutter/UGemCutter-linux/Ultimate"
```

## Compile a spec

`compile` translates `.prop` to a backend artifact. The default backend is
Boogie.

```bash
./src/bin/procurator compile \
  --spec benchmarks/specs/smoke/netchain_bug.prop \
  --out .tmp/procurator/tutorial/netchain_bug.bpl
```

The command:

- parses the `.prop` file;
- invokes P4B for imported P4 programs;
- applies environment modeling and slicing;
- emits a Boogie harness at the output path.

Run a structural check:

```bash
./src/bin/procurator smoke \
  --bpl .tmp/procurator/tutorial/netchain_bug.bpl \
  --harness concurrent
```

`smoke` does not prove the property. It checks that the generated Boogie has the
expected harness shape.

## Verify NetChain

The NetChain wraparound example is:

```text
benchmarks/specs/bench/netchain_wraparound_bug.prop
```

It imports two NetChain P4 programs, connects them in order, models one host,
and checks sequence monotonicity:

```text
s1_sequence_reg[0] >= s2_sequence_reg[0]
```

Run:

```bash
./src/bin/procurator verify \
  --spec benchmarks/specs/bench/netchain_wraparound_bug.prop \
  --ultimate "$ULTIMATE" \
  --toolchain ReachSafety.xml \
  --settings ReachSafety-32bit-GemCutter-internal.epf \
  --wraparound auto
```

`--wraparound auto` is the default. Procurator infers wraparound candidates and
runs the integrated CEGIS pipeline before ordinary GemCutter verification. The
pipeline searches for a reachable counter state, confirms the violation after
fast-forwarding, and checks closure for the chosen projection.

A successful bug-finding run prints `RESULT: UNSAFE` or
`[WRAP] CERTIFIED UNSAFE`. The run directory is printed in the command output
and is created under:

```text
.tmp/procurator/verify/netchain_wraparound_bug/<run_id>/
```

Important files in a run directory:

```text
netchain_wraparound_bug.bpl                         generated Boogie
gemcutter.log or gemcutter.witness.log              solver log
netchain_wraparound_bug.bpl-witness.graphml         witness graph
netchain_wraparound_bug.bpl-witness.yml             witness metadata
wraparound/**/wraparound.cegis.manifest.json        wraparound certificate
```

## Read results

Use the result status conservatively.

```text
UNSAFE   A violating execution was found for the generated model.
SAFE     The selected model and bound passed.
TIMEOUT  The run did not finish within the selected timeout.
UNKNOWN  The solver did not produce a conclusive result.
ERROR    The toolchain failed.
```

`UNSAFE` evidence is valid for bug finding even when the model is bounded.
`SAFE` under `--max-steps` or `--use-spec-max-steps` is only a bounded result.
`TIMEOUT`, `UNKNOWN`, OOM, toolchain errors, missing witnesses, and unaudited
`SAFE` results are inconclusive.

## Use archived examples

The repository includes an archived core dataset:

```text
artifact/results/core_28/core_28.casewise.actual.json
artifact/results/core_28/cases/
artifact/results/core_28/e/
```

Check it in place:

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

Run one benchmark and one mode:

```bash
artifact/scripts/run_benchmark_case.sh \
  --bench netchain_wraparound_bug \
  --only slicing \
  --ultimate "$ULTIMATE"
```

Casewise runs are easier to inspect than a single large solver campaign. Each
case produces one actual JSON file and one run directory.
