# Examples and result data

`artifact/` contains reproducible workflows, expected profiles, and archived
result data for Procurator.

It is useful for three tasks:

- installing the pinned Ultimate/GemCutter runtime;
- running smoke, single-case, and curated benchmark workflows;
- inspecting archived result evidence without rerunning the solver.

## Entrypoints

```text
scripts/setup_gemcutter.sh              install pinned Ultimate/GemCutter
scripts/run_smoke.sh                    run CLI, compile, and optional solver smoke
scripts/run_benchmark_case.sh           run one benchmark and one mode
scripts/run_core_28_casewise.sh         run the curated 28-case suite case by case
scripts/run_wraparound_4.sh             run the four wraparound benchmarks
scripts/run_compile_runtime.sh          measure compile/runtime data from results
scripts/check_expected.py               compare actual JSON against expected profiles
scripts/merge_case_results.py           merge per-case actual JSON files
scripts/make_tables.py                  generate CSV summaries
scripts/validate_witnesses.py           validate UNSAFE evidence paths
scripts/validate_wraparound_manifests.py validate wraparound certificates
```

Large workflows are casewise by default. A single case is easier to inspect,
resume, and report than one monolithic solver campaign.

## Archived core dataset

The repository includes the 2026-07-04 casewise result dataset for the curated
28 benchmarks.

```text
results/core_28/core_28.casewise.actual.json   combined checker input
results/core_28/cases/                         56 per-benchmark/per-mode JSON files
results/core_28/e/                             BPL, witnesses, logs, replay records, manifests
results/core_28/MANIFEST.json                  machine-readable inventory
evidence/core_28_casewise_reproduction_20260704.md
evidence/actor_wraparound_audit_28_cases.md
```

The archived dataset contains 28 benchmark specs and 56 mode records. Each mode
record stores the command, status, sanity classification, run id, runtime, and
evidence path.

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

Validate UNSAFE evidence paths:

```bash
PYTHONPATH=src:src/p4b/python artifact/scripts/validate_witnesses.py \
  --results-json artifact/results/core_28/core_28.casewise.actual.json
```

Validate wraparound manifests:

```bash
PYTHONPATH=src:src/p4b/python artifact/scripts/validate_wraparound_manifests.py \
  --results-json artifact/results/core_28/core_28.casewise.actual.json
```

## Run a single case

```bash
artifact/scripts/run_benchmark_case.sh \
  --bench netchain_wraparound_bug \
  --only slicing \
  --ultimate "$ULTIMATE"
```

`--only` accepts `slicing`, `noslicing`, or `all`. The script writes an actual
JSON file under `.tmp/procurator/artifact/cases/` and validates that file.

## Run the curated suite

```bash
artifact/scripts/run_core_28_casewise.sh
```

The wrapper discovers the curated benchmark list, runs each benchmark in
`slicing` and `noslicing` mode, merges the per-case actual JSON files, and
checks the combined profile.

`run_core_28.sh` is a compatibility wrapper. It delegates to
`run_core_28_casewise.sh` unless `ALLOW_BATCH_CORE_28=1` is set.

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
