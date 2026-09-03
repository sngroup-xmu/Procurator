# Artifact: reproducible workflows and archived results

`artifact/` contains everything needed to reproduce the evaluation of
Procurator (SIGCOMM'26): environment setup, pinned solver toolchain, the
curated 28-bug suite, the wraparound certificate audit, and the archived
2026-07-04 result dataset.

## One-shot reproduction

```bash
artifact/scripts/run_all.sh
```

This runs every step below in order and stops at the first failed
expected-profile check. Expect about 2-4 hours of total wall time on a
16-core Linux/WSL host. All transient output lands under
`.tmp/procurator/artifact/`; nothing under `artifact/` is modified.

Paper-claim map:

| Paper claim | Script | Output |
|---|---|---|
| §8.1: 28 bugs across 12 systems (Table 1) | `run_core_28_casewise.sh` | all 28 x {slicing, noslicing} `UNSAFE` |
| §8.3: slicing ablation (Table 3) | `run_core_28_casewise.sh` then `run_compile_runtime.sh` | per-mode wall times |
| §8.3: wraparound acceleration (Figure 13) | `run_wraparound_4.sh` | 4 tasks, ENTRY/CONFIRM/CLOSURE certificates |

§8.2 (comparison against p4tv) is not part of this artifact because p4tv is
not publicly distributable.

## 0. Environment setup (run once, in order)

Use Linux or WSL2. On Ubuntu 24.04 (see `docker/Dockerfile`):

```bash
sudo apt-get update && sudo apt-get install -y --no-install-recommends \
  git ca-certificates curl wget unzip python3 python3-venv \
  build-essential cmake pkg-config bison flex libfl-dev \
  libgc-dev libgmp-dev \
  libboost-dev libboost-iostreams-dev libboost-graph-dev \
  openjdk-21-jre-headless z3

python3 -m venv .venv-wsl
.venv-wsl/bin/pip install -r src/dslc/requirements.txt

# P4B translator (P4 -> Boogie frontend), about 10-30 min:
mkdir -p src/p4b/source/build-host && cd src/p4b/source/build-host
cmake -DP4C_USE_GOLD=OFF -DENABLE_GTESTS=OFF ..
cmake --build . --target p4c-translator -j"$(nproc)"
cd -

# Pinned Ultimate/GemCutter solver (version + sha256 are fixed in the script):
artifact/scripts/setup_gemcutter.sh
```

`setup_gemcutter.sh` is the only network-dependent step after `apt`. If the
bdwgc FetchContent clone of the P4B build is blocked, use the system package
instead: `cmake -DP4C_USE_PREINSTALLED_BDWGC=ON ...` (requires `libgc-dev`).

## 1. Smoke test (about 1 min)

```bash
artifact/scripts/run_smoke.sh
```

Checks the CLI, the P4B-to-Boogie compile path, and (if the solver is
installed) one solver run. Writes `.tmp/procurator/artifact/smoke.actual.json`
and validates it against `expected/smoke.expected.json`.

## 2. Core 28-bug suite (2-4 h; the main experiment)

```bash
artifact/scripts/run_core_28_casewise.sh
```

Discovers the 28 curated benchmarks, runs each in `slicing` and `noslicing`
mode (56 solver runs), merges the per-case JSON files, and checks the combined
profile against `expected/core_28.expected.json`. The slicing/noslicing pair
per benchmark is also the §8.3 slicing ablation data.

A single case (useful for inspection or resuming):

```bash
artifact/scripts/run_benchmark_case.sh --bench netchain_wraparound_bug --only slicing
```

`--only` accepts `slicing`, `noslicing`, or `all`. `--dry-run` prints the
exact commands without executing them.

## 3. Wraparound certificate audit (4 tasks)

```bash
artifact/scripts/run_wraparound_4.sh
```

Re-runs the four wraparound-required benchmarks (NetChain, two DistCache P2C
cases, FissLock) and validates the ENTRY/CONFIRM/CLOSURE certificates via
`validate_wraparound_manifests.py`.

## 4. Compile/runtime table and CSV summary

```bash
artifact/scripts/run_compile_runtime.sh   # from the core_28 records
artifact/scripts/make_tables.py           # CSV summary
```

## Pinned hyperparameters

These are fixed in the scripts and match the archived dataset exactly:

- solver: Ultimate/GemCutter `v0.3.1` (sha256-pinned in `setup_gemcutter.sh`)
- solver settings profile: `src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL.epf`
  (external Z3). Do not switch to the `-internal` (SMTInterpol) profile: it
  returns `UNKNOWN`/`TIMEOUT` on several implementation/functional cases.
- solver timeout: 900 s per task (1800 s for two tasks); override with
  `TIMEOUT_SECONDS`
- solver heap: 4 GB per run; override with `ULTIMATE_XMX_GB`
- harness: sequential Boogie harness, no two-stage encoding; `--wraparound auto`
  for wraparound-class benchmarks, `--wraparound off` otherwise

## Archived 2026-07-04 dataset (inspect without rerunning)

```text
results/core_28/core_28.casewise.actual.json   combined checker input
results/core_28/cases/                         56 per-benchmark/per-mode JSON files
results/core_28/e/                             BPL, witnesses, logs, replay records, manifests
results/core_28/MANIFEST.json                  machine-readable inventory
evidence/core_28_casewise_reproduction_20260704.md
evidence/actor_wraparound_audit_28_cases.md
```

Every archived mode record is `UNSAFE` with sanity `OK`. Check it in place:

```bash
artifact/scripts/check_expected.py \
  --expected artifact/expected/core_28.expected.json \
  --actual artifact/results/core_28/core_28.casewise.actual.json
```

Validate UNSAFE evidence paths and wraparound certificates:

```bash
PYTHONPATH=src:src/p4b/python artifact/scripts/validate_witnesses.py \
  --results-json artifact/results/core_28/core_28.casewise.actual.json
PYTHONPATH=src:src/p4b/python artifact/scripts/validate_wraparound_manifests.py \
  --results-json artifact/results/core_28/core_28.casewise.actual.json
```

## Result policy

The checkers are conservative.

```text
UNSAFE   accepted when the required witness or manifest exists
SAFE     accepted only when the expected profile allows it
TIMEOUT  rejected as inconclusive
UNKNOWN  rejected as inconclusive
ERROR    rejected as inconclusive
MISSING  rejected
```

Do not count `TIMEOUT`, `UNKNOWN`, OOM, toolchain errors, missing witnesses, or
unaudited `SAFE` as bug absence.
