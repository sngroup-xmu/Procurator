# Artifact Workflow

This directory is the reviewer-facing layer for the SIGCOMM26 artifact. It is
separate from `src/` so that source code, benchmark inputs, and reproducibility
machinery remain auditable.

Planned entrypoints:

- `scripts/run_smoke.sh`: short environment and CLI check.
- `scripts/run_core_28.sh`: curated 28-case experiment runner.
- `scripts/run_wraparound_4.sh`: wraparound certification runner.
- `scripts/make_tables.py`: regenerate paper-facing tables from raw evidence.

Current status: the directory contains the public artifact skeleton and
evidence manifests. Before archival, fill the expected result files from fresh
runs and validate that every reported `UNSAFE`, witness, and wraparound
certificate has the corresponding artifact path recorded. Inconclusive outcomes
(`TIMEOUT`, `UNKNOWN`, OOM, toolchain errors, missing witnesses, or unverified
`SAFE`) must remain inconclusive.
