# Artifact Workflow

This directory is the reviewer-facing layer for the SIGCOMM26 artifact. It is
separate from `src/` so that source code, benchmark inputs, and reproducibility
machinery remain auditable.

Entrypoints:

- `scripts/setup_gemcutter.sh`: download the pinned Ultimate GemCutter Linux
  release into ignored `.tmp/` local state.
- `scripts/run_smoke.sh`: short CLI, P4B compile, and optional solver smoke.
- `scripts/run_benchmark_case.sh`: run and check one benchmark selector at a
  time, optionally for only `slicing` or `noslicing`.
- `scripts/run_core_28.sh`: curated 28-case experiment runner.
- `scripts/run_wraparound_4.sh`: wraparound certification runner.
- `scripts/make_tables.py`: regenerate paper-facing tables from raw evidence.
- `scripts/check_expected.py`: fail-closed checker for expected/actual JSON.

Typical local setup:

```bash
artifact/scripts/setup_gemcutter.sh
artifact/scripts/run_smoke.sh
```

The smoke profile writes `.tmp/procurator/artifact/smoke.actual.json`. It
requires CLI help and P4B-to-Boogie compilation to pass. A short solver smoke is
recorded when Ultimate is available, but `TIMEOUT`, `UNKNOWN`, OOM, toolchain
errors, missing witnesses, and unverified `SAFE` remain inconclusive.

For development and regression work, run large benchmarks one case at a time:

```bash
artifact/scripts/run_benchmark_case.sh --bench netchain_wraparound_bug --only slicing
artifact/scripts/run_benchmark_case.sh --bench netchain_wraparound_bug --only noslicing
```

Single-case runs write `.tmp/procurator/artifact/cases/*.actual.json` and then
validate that case fail-closed. After tuning one case, re-run previously passed
case JSONs with the same script before moving on.

Full profiles may take hours and should be run in WSL or Linux:

```bash
artifact/scripts/run_core_28.sh
artifact/scripts/run_wraparound_4.sh
artifact/scripts/run_compile_runtime.sh
```

Each script writes an actual JSON under `.tmp/procurator/artifact/` and then
checks it against `artifact/expected/`. The checkers fail closed: focused
diagnostics are not accepted as wraparound certification, and a missing witness
or manifest is a failed artifact check.
