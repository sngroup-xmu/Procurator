# Procurator architecture

Procurator is organized around one CLI and a small set of implementation
boundaries.

- `src/dslc/` owns the DSL, distributed harness, actor scheduling, wraparound
  orchestration, certificates, and toolchain runners.
- `src/p4b/source/` owns P4-local translation through the pinned P4B/p4c fork
  and `p4c-translator`.
- `benchmarks/` contains runnable specifications, P4 programs, table entries,
  and configs.
- `artifact/` contains reproducible example workflows, expected profiles, and
  archived result data.

The runtime pipeline is:

```text
procurator CLI
  -> DSL parse
  -> P4B import translation
  -> DSLC actor harness generation
  -> Boogie output
  -> Ultimate/GemCutter execution
  -> logs, witnesses, manifests, and actual JSON
```
