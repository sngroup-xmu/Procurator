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
- `scripts/run_core_28_casewise.sh`: run the curated 28-case experiment one
  benchmark/mode at a time, merge the per-case JSON files, and check the
  combined result fail-closed.
- `scripts/run_core_28.sh`: curated 28-case experiment runner.
- `scripts/run_wraparound_4.sh`: wraparound certification runner.
- `scripts/merge_case_results.py`: merge `.tmp/procurator/artifact/cases/*.actual.json`
  files into a combined `core_28` checker input.
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

For a complete core-28 reproduction that keeps this case-by-case discipline,
use:

```bash
artifact/scripts/run_core_28_casewise.sh
```

This wrapper does not launch all 28 cases as one solver campaign. It discovers
the curated benchmark list, runs each benchmark in `slicing` and then
`noslicing` mode through `run_benchmark_case.sh`, merges the resulting per-case
JSON files into `.tmp/procurator/artifact/core_28.casewise.actual.json`, and
checks that combined file against `artifact/expected/core_28.expected.json`.
`run_compile_runtime.sh` uses that casewise JSON by default when it exists; set
`RESULTS_JSON=<path>` only when you intentionally want a different E2E result
file.

Full profiles may take hours and should be run in WSL or Linux:

```bash
artifact/scripts/run_core_28_casewise.sh
artifact/scripts/run_wraparound_4.sh
artifact/scripts/run_compile_runtime.sh
```

`run_wraparound_4.sh` follows the same casewise pattern for the four
wraparound-certification benchmarks: each benchmark is run in `slicing` and
then `noslicing` mode through `run_benchmark_case.sh`, the resulting per-case
JSON files are merged into `.tmp/procurator/artifact/wraparound_4.actual.json`,
and certified manifests are checked after the expected-profile gate.

Each script writes an actual JSON under `.tmp/procurator/artifact/` and then
checks it against `artifact/expected/`. The checkers fail closed: focused
diagnostics are not accepted as wraparound certification, and a missing witness
or manifest is a failed artifact check.
