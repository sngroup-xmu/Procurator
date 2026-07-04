---
name: procurator
description: Use Procurator to compile and verify distributed, stateful P4 systems from .prop specifications.
---

# Procurator Agent Skill

Use this skill when an agent needs to run Procurator, inspect a Procurator spec,
debug a verification run, or report Procurator evidence.

## Command surface

Use only the public CLI:

```bash
./src/bin/procurator <command> ...
```

Do not call internal Python modules as the primary user workflow unless you are
debugging the implementation itself.

## First checks

1. Read the `.prop` spec.
2. Identify imported P4 programs and table-entry files.
3. Identify topology, hosts, environment assumptions, and global assertions.
4. Decide whether the task is compile-only, ordinary verification,
   wraparound verification, or result-dataset inspection.
5. Use Linux or WSL for P4B-dependent and solver-heavy work.

## Compile before solving

Compile first when the problem may be translation or modeling:

```bash
./src/bin/procurator compile \
  --spec <spec.prop> \
  --out .tmp/procurator/agent/<name>.bpl
```

Then smoke-check the harness:

```bash
./src/bin/procurator smoke \
  --bpl .tmp/procurator/agent/<name>.bpl \
  --harness concurrent
```

If generated Boogie semantics are wrong, fix P4B or DSLC modeling before
spending solver time.

## Verify

Use `verify` for normal runs:

```bash
./src/bin/procurator verify \
  --spec <spec.prop> \
  --ultimate "$ULTIMATE" \
  --toolchain ReachSafety.xml \
  --settings ReachSafety-32bit-GemCutter-ALL.epf
```

Use `--wraparound auto` for specs with counter wraparound; it is the default.
Use `--wraparound off` only when the target is known not to require it or when
you are isolating the ordinary solver path.

## Interpret results

Report the exact status:

```text
UNSAFE   counterexample found
SAFE     selected model and bound passed
TIMEOUT  inconclusive
UNKNOWN  inconclusive
ERROR    inconclusive
```

Never report `TIMEOUT`, `UNKNOWN`, OOM, toolchain errors, missing witnesses, or
unaudited `SAFE` as bug absence.

For bounded runs, `UNSAFE` is useful bug evidence. `SAFE` is only within the
selected bound.

## Evidence to record

Record these fields for every run:

- spec path;
- command;
- date and run id;
- status and exit code;
- generated Boogie path;
- solver log path;
- witness path when present;
- wraparound manifest path when present;
- timeout and memory settings;
- interpretation boundary.

Use repository-relative paths when archiving evidence.

## NetChain example

Compile:

```bash
./src/bin/procurator compile \
  --spec benchmarks/specs/smoke/netchain_bug.prop \
  --out .tmp/procurator/agent/netchain_bug.bpl
```

Verify the wraparound case:

```bash
./src/bin/procurator verify \
  --spec benchmarks/specs/bench/netchain_wraparound_bug.prop \
  --ultimate "$ULTIMATE" \
  --toolchain ReachSafety.xml \
  --settings ReachSafety-32bit-GemCutter-ALL.epf
```

Inspect archived evidence:

```bash
artifact/scripts/check_expected.py \
  --expected artifact/expected/core_28.expected.json \
  --actual artifact/results/core_28/core_28.casewise.actual.json
```

## Toolchain choice

Start with:

```text
--toolchain ReachSafety.xml
--settings ReachSafety-32bit-GemCutter-ALL.epf
--ultimate-timeout-seconds 900
--ultimate-xmx-gb 4
```

Use witness settings when main-run witness generation is required. Use
`smallblocks`, `no-por`, 8g, or 12g settings only when the run needs that
profile and the machine has enough memory.

## Failure handling

- Missing P4B translator: build
  `src/p4b/source/build-host/backends/verify/p4c-translator` or pass
  `--p4b-bin`.
- Missing Ultimate: run `artifact/scripts/setup_gemcutter.sh` or pass
  `--ultimate`.
- Solver timeout: increase timeout only after confirming the generated Boogie
  models the intended property.
- Missing witness: keep the run inconclusive until witness generation or another
  auditable counterexample path is available.
