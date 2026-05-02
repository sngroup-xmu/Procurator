# DSLC/P4B Boundary and Refactor Spec

Status: vNext implementation spec.

This document is the ownership contract for the Boogie verification pipeline
after the refactor.  It is intentionally engineering-facing: if a feature is
implemented on the wrong side of the boundary, move it to the owner named here.

## Goals

- Keep every Python implementation file below 1300 lines and every C++/header
  implementation file below 2500 lines.
- Keep every implementation directory at 8 direct files or fewer; use
  subdirectories once a directory grows beyond that.
- Preserve generated Boogie exactly for pure refactors.  When semantics change,
  require focused tests plus at least one spec-level compile/smoke or solver run.
- Keep legacy import paths working until the full end-to-end suite is stable.
  Legacy wrappers/aliases may be deleted only after the pipeline is thoroughly
  run and recorded.
- Make P4-local instrumentation native to P4B, and keep DSLC responsible for
  distributed-system modeling and solver orchestration.

## Ownership

### P4B-Translator owns P4-local semantics

P4B is the only component that should inspect P4 IR structure directly.  It owns:

- Parser/control/action/table semantics for a single P4 program.
- BMv2 table entry parsing and action parameter binding.
- Extern-local event flags such as clone, recirculate, resubmit, digest, and
  other P4 pipeline effects.
- Register declarations, register write semantics, and native register mirrors:
  `<reg>__last_index`, `<reg>__last_value`, `<reg>__wrote_any`,
  `<reg>__wrote_index0`, and `<reg>__last0_value`.
- P4-local CFG/CDG/DDG slicing and dependency extraction.
- P4-local monotonic/affine update summaries used by wraparound acceleration.
- P4-local metadata exported through `--meta-out`.

P4B must not model distributed topology, mailboxes, host actors, global schedules,
POR over actors, or solver-stage orchestration.

### DSLC owns system-level semantics

DSLC owns everything that is defined by the `.prop` model rather than by a single
P4 program:

- DSL parsing, type checking, topology, hosts, links, environment blocks, and
  assertions.
- Node prefixing, global harness generation, pass-atomic/two-stage actor
  scheduling, mailbox/queue state, symmetry/POR guards, and sink/drop semantics.
- System-level slicing seed propagation across links.
- Projection extraction from control/data dependencies plus mailbox state for
  schedule replay certificates.
- Wraparound stage orchestration: ENTRY, NEAR_WRAP, CLOSURE, CONFIRM, fallback
  direct checking, manifest certification, and Ultimate/GemCutter invocation.
- Counterexample validation and benchmark/experiment drivers.

DSLC may keep compatibility backfills for old P4B output, but those backfills are
not the source of truth.  New P4-local instrumentation belongs in P4B.

## Interfaces

### P4B Boogie output

The P4B command line remains the node-local compiler interface.  DSLC invokes it
once per imported P4 program and then prefixes the raw Boogie unit.

Required Boogie output contract:

- One node-local `mainProcedure` with complete `modifies`.
- Declarations for all globals referenced by procedures.
- Native register mirror declarations and updates for register writes.
  The full contract is: P4B emits a register marker (`// Register <name>` before
  prefixing), the mirror globals, the `<reg>.write` body updates, and a
  `<reg>.write` `modifies` clause that names every mirror global.  DSLC fails
  fast on P4B-generated nodes that expose register-looking write helpers without
  markers or with incomplete mirrors; only legacy imported `.bpl` files may use
  the compatibility backfill.
- Stable names for event flags and table-control variables consumed by DSLC
  heuristics.
- No topology/mailbox/global scheduler state.

### P4B meta JSON

`--meta-out` is the structured side channel from P4B to DSLC.  It is append-only:
new fields may be added, existing fields must remain compatible.

Current required categories:

- Slicing metadata: kept variables/tables/statements and register index bounds.
- Register metadata: element/index types and mirror-capable registers.
- Wraparound metadata: monotonic or affine self-updates, step deltas, candidate
  registers, and supporting variable names.
- Event metadata: recirculation/clone/resubmit/digest summaries when available.
- Dependency metadata: control/data-dependency facts suitable for system-level
  projection extraction.

DSLC treats missing optional fields conservatively: it either falls back to a
less optimized encoding or to direct GemCutter/Ultimate checking.

### DSLC Boogie backend package

The Boogie backend is organized as:

```text
dslc/backends/boogie/
  __init__.py          public backend API and legacy import aliases
  compiler.py          orchestration for one `.prop -> .bpl` compilation
  merge.py             whole-system merge of prefixed node units and harness
  profile.py           optional compile-time JSONL profiling
  core/                Boogie text utilities, prefixing, type helpers
  node/                P4B invocation, node metadata, register backfills, seeds
  harness/             distributed system harness generation
    flow/              actor scheduling, links, POR, sequential/concurrent flow
    state/             mailbox, registers, startup/init state
```

New code should import from these package paths.  Old modules named
`dslc.backends.boogie_*` are compatibility aliases only.

### Wraparound workflow package

The wraparound workflow should remain split by responsibility:

```text
dslc/workflows/
  wraparound_cegis.py          orchestration and CEGAR loops
  wraparound_schedule.py       actor schedule certificate construction
  wraparound_support/
    results.py                 stage result parsing and runner support
    refinement.py              witness/env refinement synthesis
    toolchains.py              Ultimate settings/toolchain selection
    distcache.py               DistCache-specific shape/cap heuristics
```

The certificate for schedule replay records only the actor schedule array and
stable projection predicates.  Fine-grained runtime events are diagnostics, not
part of the proof certificate.  If the projection is incomplete or the observed
bug is not in the wraparound replay shape, the workflow must fall back to direct
GemCutter/Ultimate checking.

### Ultimate toolchain assets

Ultimate XML/EPF files are configuration assets, not Python implementation
modules.  They live under:

```text
dslc/toolchain/ultimate/
  toolchains/                 ReachSafety XML pipelines
  settings/automizer/         Automizer/Buchi settings
  settings/gemcutter/base/    low-memory default GemCutter profiles
  settings/gemcutter/witness/ witness-oriented GemCutter profiles
  settings/gemcutter/{4g,8g,12g}/
```

Command-line compatibility is preserved by `dslc.toolchain.ultimate_paths`:
historical paths such as
`dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL.epf` resolve to the
organized asset location.  New code should use the resolver or explicit subdir
paths; it should not reintroduce flat direct file growth in
`dslc/toolchain/ultimate/`.

## Directory/file-size policy

- C++ translation files exceeding 3000 lines must be split by semantic ownership:
  declarations/modifies, expressions/statements, externs/registers, tables, and
  metadata emission.  Current P4B translate implementation directories are:
  `translate/impl/core/` for Translator-wide state/helpers,
  `translate/impl/lowering/` for IR-to-Boogie lowering,
  `translate/impl/meta/` for metadata emission, and
  `translate/impl/support/` for support classes.
- Slicing files exceeding 2500 lines must be split into graph construction,
  dependency analysis, slice application, selftests, and metadata serialization.
- Python files exceeding 1300 lines must be split into importable support modules
  with the original public API re-exported until legacy deletion is approved.
- Test directories may group tests by feature once they exceed 8 files:
  `tests/boogie/`, `tests/wraparound/`, `tests/p4b/`, `tests/toolchain/`.

## Verification gates

For pure refactors:

1. Python import/compile smoke for moved modules.
2. Focused unit tests for touched feature areas.
3. P4B build or P4B selftest when C++ translator/slicer files change.
4. NetChain compile + Boogie smoke.
5. Exact-match comparison against a pre-refactor generated `.bpl` when available.

Run these gates stage by stage.  Do not rebuild/relink `p4c-translator` in
parallel with tests that execute the same binary under WSL/Linux; the kernel can
return `Text file busy` even when the code is correct.

For semantic changes:

1. Add a focused regression test for the bug or invariant being changed.
2. Run the focused unit tests.
3. Run at least one single-spec experiment stage by stage.
4. Append the experiment record to `AGENTS.md` with spec, time, progress, pitfalls,
   fixes, and smoke/regression status.

## Migration phases

1. Establish packages and compatibility aliases.  Generated Boogie must remain
   exact-match.
2. Move support logic out of oversized Python modules.  Keep old public imports.
3. Split oversized C++ implementation files along semantic boundaries.  Rebuild
   P4B after each phase.
4. Update internal imports to new package paths.
5. After full end-to-end validation, remove legacy compatibility shims.
