# Procurator Architecture

Procurator is split into first-party source, third-party tools, benchmark
inputs, and artifact reproduction machinery.

- `src/dslc/` owns the DSL, distributed harness, actor scheduling, wraparound
  orchestration, certificates, and toolchain runners.
- `src/p4b/source/` owns P4-local translation through the pinned P4B/p4c fork
  and `p4c-translator`.
- `benchmarks/` contains only experiment inputs.
- `artifact/` contains reviewer-facing reproduction scripts and evidence.
