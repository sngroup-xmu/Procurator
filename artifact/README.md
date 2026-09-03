# Artifact: run instructions and archived results

This artifact reproduces the Procurator evaluation: 28 curated bug-finding
tasks, each run in `slicing` and `noslicing` mode (56 solver runs), plus a
certificate audit for the four wraparound tasks and a compile/runtime table.

All commands below run from the repository root on Linux or WSL2
(Ubuntu 24.04 recommended).

**Docker alternative:** a self-contained image with the whole toolchain
(translator, solver, specs) can be built with `docker build -t procurator .`
using the root `Dockerfile`; see `artifact/docker/README.md`. With the image
built, `artifact/docker/run.sh ae` runs this whole document in one command.

## 1. Requirements

- Ubuntu 24.04 (native, WSL2, or Docker), 16 GB RAM, 20 GB free disk
- Internet access during setup (apt packages + one pinned solver download)

## 2. One-time setup

```bash
# system packages
sudo apt-get update && sudo apt-get install -y --no-install-recommends \
  git ca-certificates curl wget unzip python3 python3-venv \
  build-essential cmake pkg-config bison flex libfl-dev \
  libgc-dev libgmp-dev \
  libboost-dev libboost-iostreams-dev libboost-graph-dev \
  openjdk-21-jre-headless z3

# python environment
python3 -m venv .venv-wsl
.venv-wsl/bin/pip install -r src/dslc/requirements.txt

# P4 -> Boogie translator (10-30 min build)
mkdir -p src/p4b/source/build-host && cd src/p4b/source/build-host
cmake -DP4C_USE_GOLD=OFF -DENABLE_GTESTS=OFF ..
cmake --build . --target p4c-translator -j"$(nproc)"
cd -

# pinned Ultimate/GemCutter solver (downloads ~160 MB, sha256-checked)
artifact/scripts/setup_gemcutter.sh
```

If the cmake configure step hangs while cloning `bdwgc` from GitHub, add
`-DP4C_USE_PREINSTALLED_BDWGC=ON` to the cmake command (uses the system
`libgc-dev` package instead).

## 3. Run everything

```bash
artifact/scripts/run_all.sh
```

Runs the toolchain check, smoke test, the full 28-bug suite in both modes,
the wraparound certificate audit, and the compile/runtime table, in order.
Stops at the first failed check. Total wall time: about 2-4 hours on a
16-core machine. All output lands under `.tmp/procurator/artifact/`.

## 4. Run individual steps

```bash
artifact/scripts/run_smoke.sh              # ~1 min: CLI + compile + solver sanity
artifact/scripts/run_core_28_casewise.sh   # 2-4 h: 28 benchmarks x {slicing, noslicing}
artifact/scripts/run_wraparound_4.sh       # 4 wraparound tasks + certificate validation
artifact/scripts/run_compile_runtime.sh    # per-stage wall-time table (needs step results)
artifact/scripts/make_tables.py            # CSV summary of all verdicts
```

Run a single benchmark in a single mode:

```bash
artifact/scripts/run_benchmark_case.sh --bench atp_bug --only slicing
```

`--only` accepts `slicing`, `noslicing`, or `all`. Add `--dry-run` to any
suite script to print the exact commands without executing them.

## 5. How to read the results

### What success looks like

Every script ends with the line `expected check passed` and exit code 0.
On failure the checker prints one line per problem (which case, which mode,
what is wrong) and exits 1.

### Where the files are

```text
.tmp/procurator/artifact/
  smoke.actual.json                     smoke test verdict
  cases/<bench>.<mode>.actual.json      one file per benchmark per mode (56 total)
  core_28.casewise.actual.json          merged suite result (input to the checker)
  wraparound_4.actual.json              merged wraparound audit result
  core_28_summary.csv                   verdict table from make_tables.py
  compile_runtime.actual.json / .md     per-stage wall times
```

### The verdict fields

Each per-case JSON records, per mode (`slicing` / `noslicing`):

- `status`: `UNSAFE` / `SAFE` / `TIMEOUT` / `UNKNOWN` / `ERROR`
- `sanity`: `OK` means the verdict was double-checked (the witness rerun hits
  the violated assertion; wraparound tasks additionally carry a closure
  certificate)
- `wall_s`: wall-clock seconds
- `cmd`: the exact command that produced the result
- `out_dir`: directory with all raw artifacts of the run

How to interpret:

- `UNSAFE` + sanity `OK` — the bug reproduced. This is the expected verdict
  for all 28 benchmarks in both modes.
- `SAFE` — verified safe (only accepted where the expected profile allows it).
- `TIMEOUT` / `UNKNOWN` / `ERROR` — inconclusive. These never count as
  "no bug"; the checker rejects them.

`check_expected.py` enforces this policy against
`artifact/expected/<profile>.expected.json`. You can re-run the check on any
produced JSON:

```bash
artifact/scripts/check_expected.py \
  --expected artifact/expected/core_28.expected.json \
  --actual .tmp/procurator/artifact/core_28.casewise.actual.json
```

### Looking at a counterexample

For an `UNSAFE` case, open its `out_dir`, e.g.
`.tmp/procurator/verify/atp_bug/<run-id>/`:

- `<name>.bpl` — the Boogie program that was checked
- `<name>.bpl-witness.yml` / `.graphml` — the counterexample witness
- `gemcutter.log`, `gemcutter.witness.log` — solver logs
- `wraparound/` — for wraparound tasks only: ENTRY / CONFIRM / CLOSURE
  manifests certifying the deep-overflow trace

Bulk-validate all evidence files referenced by a results JSON:

```bash
PYTHONPATH=src:src/p4b/python artifact/scripts/validate_witnesses.py \
  --results-json .tmp/procurator/artifact/core_28.casewise.actual.json
PYTHONPATH=src:src/p4b/python artifact/scripts/validate_wraparound_manifests.py \
  --results-json .tmp/procurator/artifact/wraparound_4.actual.json
```

### Inspecting the archived results without rerunning

The repository ships the archived 2026-07-04 dataset under
`artifact/results/core_28/` (56 records, all `UNSAFE` with sanity `OK`),
plus human-readable tables in `artifact/evidence/`. Check it in place:

```bash
artifact/scripts/check_expected.py \
  --expected artifact/expected/core_28.expected.json \
  --actual artifact/results/core_28/core_28.casewise.actual.json
```

## 6. Fixed settings

The scripts pin the following so that fresh runs are comparable to the
archived dataset (each case JSON records its full command for auditing):

- solver: Ultimate/GemCutter `v0.3.1`, sha256-pinned in `setup_gemcutter.sh`
- solver settings profile:
  `src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL.epf`
  (external Z3). Do not switch to the `-internal` (SMTInterpol-only) profile:
  it returns `UNKNOWN`/`TIMEOUT` on several tasks.
- solver timeout: 900 s per task (1800 s for two tasks);
  override with `TIMEOUT_SECONDS=<seconds>`
- solver heap: 4 GB per run; override with `ULTIMATE_XMX_GB=<gb>`

## 7. Result policy

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
