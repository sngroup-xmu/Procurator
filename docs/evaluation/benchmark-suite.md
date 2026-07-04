# Benchmark suite

The public benchmark suite is rooted at `benchmarks/`. The curated core suite
contains 28 bug benchmarks, each run in `slicing` and `noslicing` mode. The
2026-07-04 casewise reproduction is archived under `artifact/results/core_28/`.

Primary files:

- `artifact/results/core_28/core_28.casewise.actual.json`: combined
  machine-readable checker input for all 28 cases.
- `artifact/results/core_28/cases/`: 56 per-benchmark/per-mode actual JSON
  files.
- `artifact/results/core_28/e/`: Boogie files, witnesses, solver logs, bounded
  replay evidence, and certified wraparound manifests.
- `artifact/evidence/core_28_casewise_reproduction_20260704.md`: readable
  reproduction table.
- `artifact/evidence/actor_wraparound_audit_28_cases.md`: actor-semantics and
  wraparound classification audit.

The four wraparound-required bugs are NetChain, two DistCache P2C cases, and
FissLock notification-counter wraparound. Their archived evidence includes
`ENTRY_CHECK`, `NEAR_WRAP`, and `CLOSURE_CHECK` manifests; focused diagnostics
alone are not counted as certification.
