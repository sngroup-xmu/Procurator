# Procurator

Procurator is a research prototype for verifying distributed, stateful P4
programs. It compiles a Procurator DSL specification into Boogie, builds a
distributed actor harness, and discharges safety properties with
Ultimate/GemCutter.

## Layout

- `src/`: first-party Procurator code.
  - `src/bin/procurator`: CLI entrypoint.
  - `src/p4b/source/`: full pinned P4B/p4c fork used to build
    `p4c-translator`.
  - `src/p4b/python/`: first-party path helpers for the P4B integration.
  - `src/dslc/`: DSL parser/compiler, Boogie harness generation, workflows,
    wraparound orchestration, toolchain runners, and tests.
- `third_party/`: pinned third-party source trees and provenance records.
  - `third_party/ultimate/`: Ultimate/GemCutter source and provenance.
  - `third_party/z3/`: Z3 provenance.
- `benchmarks/`: public benchmark inputs.
  - `benchmarks/specs/`: Procurator DSL specifications.
  - `benchmarks/datasets/`: P4 programs, table entries, and configs referenced
    by retained specs.
- `artifact/`: SIGCOMM26 AE reproduction scripts, expected outputs, manifests,
  and evidence.
- `docs/`: public design, evaluation, and troubleshooting notes.
- `tools/release/`: release-tree checks and packaging helpers.

Generated outputs should go under `.tmp/procurator/` or another explicit output
directory. They are not source.

## Build

Install the Python requirements:

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r src/dslc/requirements.txt
```

Build the pinned P4B/p4c translator:

```bash
mkdir -p src/p4b/source/build-host
cd src/p4b/source/build-host
cmake -DP4C_USE_GOLD=OFF -DENABLE_GTESTS=OFF ..
cmake --build . --target p4c-translator -j"$(nproc)"
```

The expected binary path is:

```text
src/p4b/source/build-host/backends/verify/p4c-translator
```

## Smoke

```bash
artifact/scripts/setup_gemcutter.sh
artifact/scripts/run_smoke.sh
```

The GemCutter runtime is downloaded into ignored `.tmp/` local state. The smoke
script records short solver outcomes honestly; `TIMEOUT` remains inconclusive.

For artifact-oriented workflows, start from `artifact/README.md`.

## Evidence Rules

Result reporting must fail closed. Do not treat `TIMEOUT`, `UNKNOWN`, OOM,
toolchain `ERROR`, missing witnesses, or unverified `SAFE` results as bug
absence. Wraparound certification requires the intended stage evidence, not only
focused diagnostics.
