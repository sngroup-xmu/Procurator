# Procurator GemCutter Benchmarks (Max-Env)

This folder collects compiled artifacts and verification outputs for the current DSL -> Boogie -> Ultimate/GemCutter flow. All benchmarks in `max_env/` are run with fully nondeterministic external inputs (`--env max`).

## Folder Layout

```
benchmarks_gemcutter/
  USAGE.md
  max_env/
    netchain/
      spec.prop
      netchain_bug.bpl
      netchain_bug.gemcutter.log
      netchain_bug.bpl-witness.graphml
    p4xos/
      spec.prop
      p4xos_bug.bpl
      p4xos_bug.gemcutter.log
      p4xos_bug.bpl-witness.graphml
    atp/
      spec.prop
      atp_bug.bpl
      atp_bug.gemcutter.log
      atp_bug.bpl-witness.graphml
    distcache/
      spec.prop
      distcache_bug.bpl
      distcache_bug.gemcutter.log
      distcache_bug.bpl-witness.graphml
    switchv2p/
      spec.prop
      switchv2p_bug.bpl
  max_env_slicing/
    netchain/
      spec.prop
      netchain_bug.slicing.bpl
      netchain_bug.slicing.gemcutter.log
      netchain_bug.slicing.bpl-witness.graphml
    p4xos/
      spec.prop
      p4xos_bug.slicing.bpl
      p4xos_bug.slicing.gemcutter.log
      p4xos_bug.slicing.bpl-witness.graphml
    atp/
      spec.prop
      atp_bug.slicing.bpl
      atp_bug.slicing.gemcutter.log
      atp_bug.slicing.bpl-witness.graphml
    distcache/
      spec.prop
      distcache_bug.slicing.bpl
      distcache_bug.slicing.gemcutter.log
      distcache_bug.slicing.bpl-witness.graphml
    switchv2p/
      spec.prop
      switchv2p_bug.slicing.bpl
      switchv2p_bug.slicing.gemcutter.log
  max_env_internal/
    netchain/
      spec.prop
      netchain_bug.internal.bpl
      netchain_bug.internal.gemcutter.log
      netchain_bug.internal.bpl-witness.graphml
    p4xos/
      spec.prop
      p4xos_bug.internal.bpl
      p4xos_bug.internal.gemcutter.log
      p4xos_bug.internal.bpl-witness.graphml
    atp/
      spec.prop
      atp_bug.internal.bpl
      atp_bug.internal.gemcutter.log
      atp_bug.internal.bpl-witness.graphml
    distcache/
      spec.prop
      distcache_bug.internal.bpl
      distcache_bug.internal.gemcutter.log
      distcache_bug.internal.bpl-witness.graphml
```

## Spec Language (quick reference)

A spec file (`*.prop`) is a DSL with four main blocks. The spec language lives under `dslc/speclang`, and the compiler entrypoint is `dslc`.

```
import <alias> from "<p4_path>" [entries "<commands.txt>"];

topology {
  link <src> -> <dst> <port|ALL>;
}

node <alias> {
  external_input = true|false;
  assume { <boolean constraints>; };
}

global {
  queue_capacity = <int>;
  assert { <boolean property>; };
}
```

Rules and notes:
- `import` defines a P4 program per node. Optional `entries` points to table commands.
- `topology` defines forwarding between nodes. `ALL` means any egress port.
- `external_input = true` enables nondeterministic packet injection for the node.
- `assume { ... }` constrains packet fields when the node is an external input.
- `assert { ... }` is a safety property checked on every pass in the generated Boogie harness.
- `symmetry(n1, n2, ...)` (global) adds symmetry-breaking constraints that order `n*_inbox_count`.
- NetChain local-cutoff specs:
  - `max_env/netchain/spec_pair12.prop` (s1->s2)
  - `max_env/netchain/spec_pair23.prop` (s2->s3)
- For bitvectors, `>=` / `<` are lowered to `bvule` plus a strictness check, so you may see `bvule.bvXX(x, y) && x != y` in generated Boogie/witnesses.

## How to Run (compile + GemCutter)

All commands below run in max-env mode and enable witness generation.

Java/runtime note:
- If Ultimate was built with Java 25, set `JAVA_HOME`/`PATH` accordingly to avoid `UnsupportedClassVersionError` when the external solver plugin loads.
- Example prefix:
  `JAVA_HOME=/home/smy/.cursor-server/data/User/globalStorage/pleiades.java-extension-pack-jdk/java/latest PATH=$JAVA_HOME/bin:$PATH`

Disable slicing/pruning (recommended for translation debugging):

```bash
./bin/procurator verify \
  --spec <spec.prop> \
  --p4b-bin P4B-Translator/build-host/p4c-translator \
  --ultimate UGemCutter-linux/Ultimate \
  --env max \
  --no-slicing \
  --no-env-prune \
  --toolchain dslc/toolchain/ultimate/ReachSafety-Witness.xml \
  --settings dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-witness.epf
```

Pruning (default on) with internal SMTInterpol:

```bash
./bin/procurator verify \
  --spec <spec.prop> \
  --p4b-bin P4B-Translator/build-host/p4c-translator \
  --ultimate UGemCutter-linux/Ultimate \
  --env max \
  --toolchain dslc/toolchain/ultimate/ReachSafety-Witness.xml \
  --settings dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-internal-witness.epf
```

Compose mode (split global conjuncts into local specs and run in parallel):

```
./bin/procurator verify \
  --spec <spec.prop> \
  --compose \
  --compose-max-nodes 2 \
  --compose-jobs 2 \
  --compose-local-inputs \
  --p4b-bin P4B-Translator/build-host/p4c-translator \
  --ultimate UGemCutter-linux/Ultimate \
  --env max \
  --toolchain dslc/toolchain/ultimate/ReachSafety-Witness.xml \
  --settings dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-internal-witness.epf
```

Outputs (compose mode):
- Compose artifacts are under `<out_dir>/compose/` (where `<out_dir>` is the per-run directory printed by `procurator`).

Outputs (default):
- Per-run output dir (no cache): `.tmp/procurator/verify/<spec>/<run_id>/`
- Boogie program: `<out_dir>/<spec>.bpl`
- Ultimate log: `<out_dir>/gemcutter.log` (or `<spec>.gemcutter.log` if `--out` is provided)
- GraphML witness: `<out_dir>/<spec>.bpl-witness.graphml` (if UNSAFE)

## How to Read the Trace (GraphML witness)

Each GraphML witness encodes the counterexample path as edges with `sourcecode` and optional `assumption`. For our DSL properties, the violating edge is the `assert ...` statement inserted by the harness.

Practical checks:
1) Confirm the run is UNSAFE in the `.gemcutter.log` (`RESULT: Ultimate proved your program to be incorrect!`).
2) In the `.bpl-witness.graphml`, find `sourcecode` with `assert ...` matching the DSL property.
3) Confirm that the `assert` is the last edge before the node marked `<data key="violation">true</data>`.

## Benchmarks and Trace Validation

### Netchain
- Spec: `max_env/netchain/spec.prop`
- Result: UNSAFE
- Witness: `max_env/netchain/netchain_bug.bpl-witness.graphml`
- Property: sequence monotonicity across replicas
  - DSL: `(s1_sequence_reg_0[0] >= s2_sequence_reg_0[0]) && (s2_sequence_reg_0[0] >= s3_sequence_reg_0[0])`
  - Witness shows the failing edge:
    - `assert bvule.bv16(s2_sequence_reg_0[0bv32], s1_sequence_reg_0[0bv32]) && bvule.bv16(s3_sequence_reg_0[0bv32], s2_sequence_reg_0[0bv32]);`
  - This is the bitvector form of the DSL property; the violation indicates a real counterexample under max-env inputs.
  - Slicing witness (matches the same assert): `max_env_slicing/netchain/netchain_bug.slicing.bpl-witness.graphml`

### P4XOS
- Spec: `max_env/p4xos/spec.prop`
- Result: UNSAFE
- Witness: `max_env/p4xos/p4xos_bug.bpl-witness.graphml`
- Property: Paxos instance index bound
  - DSL: `acceptorX_hdr.paxos.inst < 300` for X in {0,1,2}
  - Witness edges include:
    - `assert bvule.bv32(acceptor0_hdr.paxos.inst, 300bv32) && acceptor0_hdr.paxos.inst != 300bv32;`
    - (and similarly for acceptor1/2)
  - This is the strict `< 300` bound; UNSAFE confirms a reachable violation.
  - Slicing witness (same assert set): `max_env_slicing/p4xos/p4xos_bug.slicing.bpl-witness.graphml`

### ATP
- Spec: `max_env/atp/spec.prop`
- Result: UNSAFE
- Witness: `max_env/atp/atp_bug.bpl-witness.graphml`
- Property: aggregator index bound
  - DSL: `s1_hdr.p4ml_agtr_index.agtr < 20479`
  - Witness edge:
    - `assert bvule.bv16(s1_hdr.p4ml_agtr_index.agtr, 20479bv16) && s1_hdr.p4ml_agtr_index.agtr != 20479bv16;`
  - This is the strict `< 20479` bound; UNSAFE confirms a reachable violation.
  - Slicing witness (matches the same assert): `max_env_slicing/atp/atp_bug.slicing.bpl-witness.graphml`

## Slicing vs Base (time + trace)

Times are extracted from GemCutter logs ("Toolchain (without parser) took X ms").

| system   | base ms | slicing ms | speedup | trace assert match |
|----------|---------|------------|---------|--------------------|
| netchain | 9195.43 | 3100.00 | 2.97x | yes |
| atp      | 8216.09 | 2200.00 | 3.73x | yes |
| p4xos    | 90840.49 | 58100.00 | 1.56x | yes |
| distcache | 387511.80 | 324900.00 | 1.19x | yes |

SwitchV2P (slicing): timeout at 600s; see `Procurator/argo/code/results/benchmarks_gemcutter/max_env_slicing/switchv2p/switchv2p_bug.slicing.gemcutter.log`

Full summary: `Procurator/argo/code/results/benchmarks_gemcutter/max_env_slicing/RESULTS.md`
Baseline (no-prune, internal SMTInterpol): `Procurator/argo/code/results/benchmarks_gemcutter/max_env_internal/`

Latest internal SMTInterpol re-runs (2026-01-07, slicer fix for RegisterAction/execute):
- P4XOS: base OverallTime 98.4s, slicing OverallTime 79.2s, same assert line in witness.
- ATP: base OverallTime 4.8s, slicing OverallTime 4.0s, same assert line in witness.
- NetChain: slicing run did not finish within 30 minutes; log pending.

### DistCache
- Spec: `max_env/distcache/spec.prop`
- Result: UNSAFE (longer run, ~23 minutes)
- Witness: `max_env/distcache/distcache_bug.bpl-witness.graphml`
- Property: power-of-two-choice consistency
  - DSL:
    - `(leafload <= spineload) || (is_spine == 1)`
    - `(leafload > spineload) || (is_spine == 0)`
  - Witness edges show the lowered asserts:
    - `assert bvule.bv32(clientTrack_leafload_0, clientTrack_spineload_0) || clientTrack_meta.is_spine == 1bv1;`
    - `assert (bvule.bv32(clientTrack_spineload_0, clientTrack_leafload_0) && clientTrack_leafload_0 != clientTrack_spineload_0) || clientTrack_meta.is_spine == 0bv1;`
  - The strict `>` is encoded as `bvule(spineload, leafload) && leafload != spineload`.
  - Slicing witness (same assert): `max_env_slicing/distcache/distcache_bug.slicing.bpl-witness.graphml`

### SwitchV2P (expected SAFE/unknown)
- Spec: `max_env/switchv2p/spec.prop`
- Status: no counterexample found (consistent with the original paper).
- Artifact: `max_env/switchv2p/switchv2p_bug.bpl`
- Future work: extend runtime or switch to proof settings for eventual safety confirmation.

## Notes on Max-Env Inputs

When `external_input = true` and `--env max` is selected, inputs are fully nondeterministic. Any UNSAFE result means a counterexample exists within this over-approximation and is encoded in the witness.

## Benchmark Summary (No-cache, 2026-01-30)

The runs below were executed with the current `./bin/procurator` CLI, which always creates a *fresh* per-run output directory under `.tmp/procurator/...` (no reuse of old `.bpl`, Ultimate HOME, or logs).

Common Ultimate settings:
- Ultimate binary: `.tmp/orphan-worktree-20260129-005608/UGemCutter-linux/Ultimate`
- Settings: `dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-no-por.epf`
- Timeout: `verify`: `300s` for small bugs, `600s` for DistCache; `wraparound`: `1200s` per stage
- Verify toolchain: `dslc/toolchain/ultimate/ReachSafety-Witness.xml`
- Wraparound toolchain: `dslc/toolchain/ultimate/ClosureCheck-ReachSafety.xml` (no witness printer; avoids Ultimate NPE on some SAFE closure checks)

Times below are wall-clock seconds for the full `procurator` invocation (P4B compile + Ultimate), reported by `/usr/bin/time` as `WALLTIME_SEC=...`.

| bug / benchmark | spec | optimized (slicing on, env-prune on unless noted) | opt time (s) | opt result | baseline (ablation) | base time (s) | base result | OOM? | pseudo? / notes |
|---|---|---:|---:|---|---:|---:|---|---|---|
| Netchain fast-forward | `Procurator/argo/code/spec/bench/netchain_bug_s1s2_fastforward.prop` | `verify --boogie-harness concurrent --env spec --max-steps 2` | 55.35 | UNSAFE | `verify --no-slicing --no-env-prune --boogie-harness concurrent --env spec --max-steps 2` | 62.67 | UNSAFE | no | UNSAFE is sound. Baseline can be faster on some instances due to solver heuristics. |
| ATP bound bug | `Procurator/argo/code/spec/bench/atp_bug.prop` | `verify --env max --max-steps 5` | 31.66 | UNSAFE | `verify --no-slicing --no-env-prune --env max --max-steps 5` | 82.59 | UNSAFE | no | UNSAFE is sound under `env=max` over-approximation. |
| DistCache leaf pktloss clone/drop | `Procurator/argo/code/spec/bench/distcache_leaf_pktloss_clone_drop_bug.prop` | `verify --boogie-harness sequential --env spec --max-steps 5` | 99.44 | UNSAFE | `verify --no-slicing --no-env-prune --boogie-harness sequential --env spec --max-steps 5` | 74.19 | toolchain no result | yes | Baseline hits Z3 OOM (`(error \"out of memory\")`, -memory:2024) and crashes the toolchain. |
| DistCache CM3/CM4 write wiring | `Procurator/argo/code/spec/bench/distcache_cm34_write_bug.prop` | `verify --boogie-harness sequential --env spec --max-steps 4` | 51.92 | UNSAFE | `verify --no-slicing --no-env-prune --boogie-harness sequential --env spec --max-steps 4` | 56.31 | toolchain no result | yes | Baseline hits Z3 OOM (`(error \"out of memory\")`, -memory:2024) and crashes the toolchain. |
| DistCache P2C consistency (hard) | `Procurator/argo/code/spec/bench/distcache_bug.prop` | `verify --env spec --max-steps 10` | 641.83 | TIMEOUT | `verify --no-slicing --no-env-prune --env spec --max-steps 10` | 661.04 | TIMEOUT | no | Still open at this bound; needs stronger pruning / different settings / smaller model. |
| DistCache leafload wrap-around (closure + confirm) | `Procurator/argo/code/spec/bench/distcache_leafload_wraparound.prop` | `wraparound --toolchain ClosureCheck-ReachSafety.xml` | 422.75 | closure_check SAFE; confirm UNSAFE | `wraparound --no-slicing --toolchain ClosureCheck-ReachSafety.xml` | 864.45 | closure_check SAFE; confirm UNSAFE | no | UNSAFE is *sound* here because confirm runs only after closure_check proves SAFE (closure of the per-round +1 summary), justifying reachability of `MAX-1` before the flip. |
| DistCache P2C wrong-choice after overflow | `Procurator/argo/code/spec/bench/distcache_p2c_wraparound_bug.prop` | `wraparound --stages closure_check,confirm --confirm-unroll 6` | 242.3 | closure_check SAFE; confirm UNSAFE | `wraparound --no-slicing --no-two-stage --stages closure_check,confirm --confirm-unroll 6` | 337.6 | closure_check SAFE; confirm UNSAFE | no | Functional wraparound bug: overflow flips the load comparison and yields a wrong P2C decision (`meta.is_spine`). UNSAFE is sound because confirm only runs after closure_check proves SAFE. |
