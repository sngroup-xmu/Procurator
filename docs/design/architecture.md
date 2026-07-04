# Procurator architecture

Procurator is organized around one CLI and a small set of implementation
boundaries. The project keeps source, benchmarks, evidence, and third-party
inputs separate so that users can run the verifier without learning the
development history of the repository.

- `src/dslc/` owns the DSL, distributed harness, actor scheduling, wraparound
  orchestration, certificates, and toolchain runners.
- `src/p4b/source/` owns P4-local translation through the pinned P4B/p4c fork
  and `p4c-translator`.
- `benchmarks/` contains runnable specifications, P4 programs, table entries,
  and configs.
- `artifact/` contains reproducible example workflows, expected profiles, and
  archived result data.
- `third_party/` records external tool provenance and pinned distributable
  runtime inputs.

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

## Translation boundary

P4B is the P4-local compiler backend. It parses imported P4 programs, lowers
parser/control/table/register behavior, and emits Boogie procedures plus
metadata that DSLC can connect to a distributed network model. P4-local
semantics belong in P4B.

DSLC owns the system-level model. It parses `.prop` files, builds the topology,
models hosts, queues, actor scheduling, environment assumptions, global
assertions, and wraparound acceleration. Distributed orchestration and proof
workflow logic belong in DSLC.

This split keeps the P4 compiler fork usable on its own while allowing the
network verifier to evolve its harness and evidence model independently.

## Toolchain profiles

Ultimate toolchains and settings are source assets under:

```text
src/dslc/toolchain/ultimate/toolchains/
src/dslc/toolchain/ultimate/settings/gemcutter/base/
src/dslc/toolchain/ultimate/settings/gemcutter/witness/
src/dslc/toolchain/ultimate/settings/gemcutter/4g/
src/dslc/toolchain/ultimate/settings/gemcutter/8g/
src/dslc/toolchain/ultimate/settings/gemcutter/12g/
```

`procurator verify` defaults to `ReachSafety.xml` plus
`ReachSafety-32bit-GemCutter-internal.epf`. The profile lives in the source tree,
not in `tmp/`, and is resolved by basename from the organized settings
directories. Witness and high-memory profiles are explicit choices for runs that
need those behaviors.

Generated outputs go under `.tmp/procurator/` by default. They are runtime
artifacts, not source configuration.
