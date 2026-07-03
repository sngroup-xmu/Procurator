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
./src/bin/procurator verify \
  --spec <spec.prop> \
  --p4b-bin src/p4b/source/build-host/backends/verify/p4c-translator \
  --ultimate UGemCutter-linux/Ultimate \
  --env max \
  --no-slicing \
  --no-env-prune \
  --toolchain src/dslc/toolchain/ultimate/ReachSafety-Witness.xml \
  --settings src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-witness.epf
```

Pruning (default on) with internal SMTInterpol:

```bash
./src/bin/procurator verify \
  --spec <spec.prop> \
  --p4b-bin src/p4b/source/build-host/backends/verify/p4c-translator \
  --ultimate UGemCutter-linux/Ultimate \
  --env max \
  --toolchain src/dslc/toolchain/ultimate/ReachSafety-Witness.xml \
  --settings src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-internal-witness.epf
```

Compose mode (split global conjuncts into local specs and run in parallel):

```
./src/bin/procurator verify \
  --spec <spec.prop> \
  --compose \
  --compose-max-nodes 2 \
  --compose-jobs 2 \
  --compose-local-inputs \
  --p4b-bin src/p4b/source/build-host/backends/verify/p4c-translator \
  --ultimate UGemCutter-linux/Ultimate \
  --env max \
  --toolchain src/dslc/toolchain/ultimate/ReachSafety-Witness.xml \
  --settings src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-internal-witness.epf
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

SwitchV2P (slicing): timeout at 600s; see `artifact/evidence/legacy-results/benchmarks_gemcutter/max_env_slicing/switchv2p/switchv2p_bug.slicing.gemcutter.log`

Full summary: `artifact/evidence/legacy-results/benchmarks_gemcutter/max_env_slicing/RESULTS.md`
Baseline (no-prune, internal SMTInterpol): `artifact/evidence/legacy-results/benchmarks_gemcutter/max_env_internal/`

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

## Notes on `procurator_bad`

In **bounded** sequential harness runs (`--max-steps N`), DSL `global { assert { ... } }` checks are accumulated into a boolean flag `procurator_bad` and asserted once at the end of the unrolled run. Seeing `procurator_bad` in `.bpl` files or witness `VAL` dumps is expected (it is *not* a crash/error). An UNSAFE witness that sets this flag corresponds to a violated DSL global assertion.

## Notes on Wraparound vs One-step Overflow/Underflow

The integrated wraparound pipeline is meant for *long-prefix* counter flips (e.g., a 16/32-bit register reaching `MAX` and overflowing to `0`), where a plain bounded run would require an impractically long prefix.

Separately, some bugs are simple arithmetic overflow/underflow caused by missing guards/clamps (e.g., decrementing a counter at `0`), which can manifest in **one step** under bitvector semantics. These are expected to reproduce even with `--wraparound off` and are categorized as `implementation` (not `wraparound`) in the E2E table.

## Benchmark Summary (No-cache, 2026-01-30)

The runs below were executed with the current `./src/bin/procurator` CLI, which always creates a *fresh* per-run output directory under `.tmp/procurator/...` (no reuse of old `.bpl`, Ultimate HOME, or logs).

Common Ultimate settings:
- Ultimate binary: `.tmp/orphan-worktree-20260129-005608/UGemCutter-linux/Ultimate`
- Settings: `src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-no-por.epf`
- Timeout: `verify`: `300s` for small bugs, `600s` for DistCache; `wraparound`: `1200s` per stage
- Verify toolchain: `src/dslc/toolchain/ultimate/ReachSafety-Witness.xml`
- Wraparound toolchain: `src/dslc/toolchain/ultimate/ClosureCheck-ReachSafety.xml` (no witness printer; avoids Ultimate NPE on some SAFE closure checks)

<!-- E2E_ABLATIONS_START -->

## E2E Ablations (Auto-Generated)
Updated on 2026-02-07 with the latest E2E runs using Ultimate `/mnt/e/p4-verify/.tmp/orphan-worktree-20260129-005608/UGemCutter-linux/Ultimate`.
Category legend:
- `functional`: 功能类（功能/一致性性质被违反）
- `implementation`: 实现类（实现细节/边界处理错误；包含因缺少 guard/clamp 导致的溢出/下溢）
- `wraparound`: 变量翻转类（需要 wraparound 加速/证书的溢出相关 bug：ENTRY/CONFIRM=UNSAFE 且 CLOSURE=SAFE）
- `interleaving`: 交错类（并发/交错导致性质被违反）
- Note: 单步算术溢出/下溢（bitvector wrap）可在很短前缀内出现，通常不需要 wraparound 管线；此类按实现类统计。

| bug / benchmark | spec | opt cmd | opt time (s) | opt result | base cmd | base time (s) | base result | notes | category |
|---|---|---|---|---|---|---|---|---|---|
| NetChain wrap-around bug (NSDI) | `benchmarks/specs/bench/netchain_wraparound_bug.prop` | `verify --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --no-slicing-control-seeds` | 374.1 | entry UNSAFE; confirm UNSAFE; closure SAFE | `verify --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --no-slicing-control-seeds --no-slicing --no-env-prune` | 787.9 | entry UNSAFE; confirm UNSAFE; closure SAFE | opt run_id `20260206-192807-e484`; stage times: entry 18.5s / confirm 73.6s / closure 282.1s; manifest: `.tmp/procurator/verify/netchain_wraparound_bug/20260206-192807-e484/wraparound/target.00.s1_sequence_reg/wraparound.cegis.manifest.json`; opt confirm witness: `.tmp/procurator/verify/netchain_wraparound_bug/20260206-192807-e484/wraparound/target.00.s1_sequence_reg/netchain_wraparound_bug.cegis.00.confirm.unroll3.bpl-witness.graphml`; base run_id `20260205-152220-4e96`; stage times: entry 33.4s / confirm 242.6s / closure 512.0s; manifest: `.tmp/procurator/verify/netchain_wraparound_bug/20260205-152220-4e96/wraparound/target.00.s1_sequence_reg/wraparound.cegis.manifest.json`; base confirm witness: `.tmp/procurator/verify/netchain_wraparound_bug/20260205-152220-4e96/wraparound/target.00.s1_sequence_reg/netchain_wraparound_bug.cegis.00.confirm.unroll3.bpl-witness.graphml` | wraparound |
| DistCache P2C spineload wrap-around bug | `benchmarks/specs/bench/distcache_p2c_spineload_wraparound_bug.prop` | `verify --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0` | 709.9 | entry UNSAFE; confirm UNSAFE; closure SAFE | `verify --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --no-slicing --no-env-prune` | 861.0 | entry UNSAFE; confirm UNSAFE; closure SAFE | opt run_id `20260205-153537-0a1a`; stage times: entry 32.5s / confirm 571.2s / closure 106.3s; manifest: `.tmp/procurator/verify/distcache_p2c_spineload_wraparound_bug/20260205-153537-0a1a/wraparound/target.00.clientTrack_partitionswitchIngress_spineload_reg/wraparound.cegis.manifest.json`; opt confirm witness: `.tmp/procurator/verify/distcache_p2c_spineload_wraparound_bug/20260205-153537-0a1a/wraparound/target.00.clientTrack_partitionswitchIngress_spineload_reg/distcache_p2c_spineload_wraparound_bug.cegis.00.confirm.unroll3.bpl-witness.graphml`; base run_id `20260205-154735-5e43`; stage times: entry 21.2s / confirm 510.0s / closure 329.8s; manifest: `.tmp/procurator/verify/distcache_p2c_spineload_wraparound_bug/20260205-154735-5e43/wraparound/target.00.clientTrack_partitionswitchIngress_spineload_reg/wraparound.cegis.manifest.json`; base confirm witness: `.tmp/procurator/verify/distcache_p2c_spineload_wraparound_bug/20260205-154735-5e43/wraparound/target.00.clientTrack_partitionswitchIngress_spineload_reg/distcache_p2c_spineload_wraparound_bug.cegis.00.confirm.unroll3.bpl-witness.graphml` | wraparound |
| DistCache P2C wrong-choice after overflow | `benchmarks/specs/bench/distcache_p2c_wraparound_bug.prop` | `verify --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --no-slicing-control-seeds` | 445.8 | entry UNSAFE; confirm UNSAFE; closure SAFE | `verify --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --no-slicing-control-seeds --no-slicing --no-env-prune` | 540.8 | entry UNSAFE; confirm UNSAFE; closure SAFE | opt run_id `20260206-220119-e63c`; stage times: entry 80.4s / confirm 211.6s / closure 153.7s; manifest: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260206-220119-e63c/wraparound/target.00.clientTrack_partitionswitchIngress_leafload_reg/wraparound.cegis.manifest.json`; opt confirm witness: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260206-220119-e63c/wraparound/target.00.clientTrack_partitionswitchIngress_leafload_reg/distcache_p2c_wraparound_bug.cegis.00.confirm.unroll3.bpl-witness.graphml`; base run_id `20260205-161436-9437`; stage times: entry 72.1s / confirm 343.8s / closure 124.9s; manifest: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260205-161436-9437/wraparound/target.00.clientTrack_partitionswitchIngress_leafload_reg/wraparound.cegis.manifest.json`; base confirm witness: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260205-161436-9437/wraparound/target.00.clientTrack_partitionswitchIngress_leafload_reg/distcache_p2c_wraparound_bug.cegis.00.confirm.unroll3.bpl-witness.graphml` | wraparound |
| FissLock: premature TRANSFER after notification_cnt wrap-around | `benchmarks/specs/bench/fisslock_notification_cnt_wraparound_bug.prop` | `verify --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --no-slicing-control-seeds --no-reg-debug` | 618.1 | entry UNSAFE; confirm UNSAFE; closure SAFE | `verify --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --no-slicing-control-seeds --no-reg-debug --no-slicing --no-env-prune` | 654.1 | entry UNSAFE; confirm UNSAFE; closure SAFE | opt run_id `20260207-123131-44d0`; stage times: entry 26.3s / confirm 441.9s / closure 149.9s; manifest: `.tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260207-123131-44d0/wraparound/target.00.sw_IngressPipe_CounterTable_1_notification_cnt_1/wraparound.cegis.manifest.json`; opt confirm witness: `.tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260207-123131-44d0/wraparound/target.00.sw_IngressPipe_CounterTable_1_notification_cnt_1/fisslock_notification_cnt_wraparound_bug.cegis.00.confirm.unroll3.bpl-witness.graphml`; base run_id `20260207-124213-5b92`; stage times: entry 29.4s / confirm 415.0s / closure 209.7s; manifest: `.tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260207-124213-5b92/wraparound/target.00.sw_IngressPipe_CounterTable_1_notification_cnt_1/wraparound.cegis.manifest.json`; base confirm witness: `.tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260207-124213-5b92/wraparound/target.00.sw_IngressPipe_CounterTable_1_notification_cnt_1/fisslock_notification_cnt_wraparound_bug.cegis.00.confirm.unroll3.bpl-witness.graphml` | wraparound |
| ATP bound bug | `benchmarks/specs/bench/atp_bug.prop` | `verify --wraparound off --no-slicing-control-seeds` | 97.6 | UNSAFE | `verify --wraparound off --no-slicing-control-seeds --no-slicing --no-env-prune` | 124.2 | UNSAFE | opt run_id `20260207-023629-7563`; witness: `.tmp/procurator/verify/atp_bug/20260207-023629-7563/atp_bug.bpl-witness.graphml`; base run_id `20260207-023800-c853`; witness: `.tmp/procurator/verify/atp_bug/20260207-023800-c853/atp_bug.bpl-witness.graphml` | implementation |
| ATP count mismatch bug | `benchmarks/specs/bench/atp_count_mismatch_bug.prop` | `verify --wraparound off --use-spec-max-steps --no-slicing-control-seeds` | 137.6 | UNSAFE | `verify --wraparound off --use-spec-max-steps --no-slicing-control-seeds --no-slicing --no-env-prune` | 239.4 | UNSAFE | opt run_id `20260206-184726-c066`; witness: `.tmp/procurator/verify/atp_count_mismatch_bug/20260206-184726-c066/atp_count_mismatch_bug.bpl-witness.graphml`; base run_id `20260206-184933-5049`; witness: `.tmp/procurator/verify/atp_count_mismatch_bug/20260206-184933-5049/atp_count_mismatch_bug.bpl-witness.graphml` | functional |
| DistCache leaf pktloss clone/drop | `benchmarks/specs/bench/distcache_leaf_pktloss_clone_drop_bug.prop` | `verify --wraparound off --use-spec-max-steps` | 257.2 | UNSAFE | `verify --wraparound off --use-spec-max-steps --no-slicing --no-env-prune --settings src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-internal-no-por.epf` | - | N/A | opt run_id `20260206-051545-73c6`; witness: `.tmp/procurator/verify/distcache_leaf_pktloss_clone_drop_bug/20260206-051545-73c6/distcache_leaf_pktloss_clone_drop_bug.bpl-witness.graphml` | functional |
| DistCache CM3/CM4 write wiring | `benchmarks/specs/bench/distcache_cm34_write_bug.prop` | `verify --wraparound off --use-spec-max-steps --no-reg-debug --no-slicing-control-seeds` | 11.2 | UNSAFE | `verify --wraparound off --use-spec-max-steps --no-reg-debug --no-slicing-control-seeds --no-slicing --no-env-prune --settings src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf` | 177.6 | UNSAFE | opt run_id `20260207-014114-6184`; witness: `.tmp/procurator/verify/distcache_cm34_write_bug/20260207-014114-6184/distcache_cm34_write_bug.bpl-witness.graphml`; base settings override: `src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf`; base run_id `20260207-012313-b30c`; witness: `.tmp/procurator/verify/distcache_cm34_write_bug/20260207-012313-b30c/distcache_cm34_write_bug.bpl-witness.graphml` | implementation |
| DistCache spine cache_frequency idx | `benchmarks/specs/bench/distcache_spine_cache_frequency_idx_bug.prop` | `verify --wraparound off --use-spec-max-steps` | 59.0 | UNSAFE | `verify --wraparound off --use-spec-max-steps --no-slicing --no-env-prune --settings src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf` | 244.4 | UNSAFE | opt run_id `20260207-010826-b949`; witness: `.tmp/procurator/verify/distcache_spine_cache_frequency_idx_bug/20260207-010826-b949/distcache_spine_cache_frequency_idx_bug.bpl-witness.graphml`; base settings override: `src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf`; base run_id `20260207-003152-d4da`; out: `.tmp/procurator/verify/distcache_spine_cache_frequency_idx_bug/20260207-003152-d4da` | implementation |
| DDOSD: window label collision (NSDI) | `benchmarks/specs/bench/ddosd_window_label_collision_bug.prop` | `verify --wraparound off --use-spec-max-steps --no-reg-debug` | 204.1 | UNSAFE | `verify --wraparound off --use-spec-max-steps --no-reg-debug --no-slicing --no-env-prune --settings src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf` | 3472.1 | UNSAFE | opt run_id `20260206-134001-5632`; witness: `.tmp/procurator/verify/ddosd_window_label_collision_bug/20260206-134001-5632/ddosd_window_label_collision_bug.bpl-witness.graphml`; base settings override: `src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf`; base run_id `20260206-114943-c00b`; witness: `.tmp/procurator/verify/ddosd_window_label_collision_bug/20260206-114943-c00b/ddosd_window_label_collision_bug.bpl-witness.graphml` | implementation |
| FRR bug1: unexpected mirror (NSDI) | `benchmarks/specs/bench/frr_bug1_unexpected_mirror.prop` | `verify --wraparound off --use-spec-max-steps --no-slicing-control-seeds` | 12.3 | UNSAFE | `verify --wraparound off --use-spec-max-steps --no-slicing-control-seeds --no-slicing --no-env-prune` | 78.2 | UNSAFE | opt run_id `20260206-221952-102a`; witness: `.tmp/procurator/verify/frr_bug1_unexpected_mirror/20260206-221952-102a/frr_bug1_unexpected_mirror.bpl-witness.graphml`; base run_id `20260205-181301-a004`; witness: `.tmp/procurator/verify/frr_bug1_unexpected_mirror/20260205-181301-a004/frr_bug1_unexpected_mirror.bpl-witness.graphml` | implementation |
| FRR bug2: state inconsistency (NSDI) | `benchmarks/specs/bench/frr_bug2_state_inconsistency.prop` | `verify --wraparound off --use-spec-max-steps` | 291.8 | UNSAFE | `verify --wraparound off --use-spec-max-steps --no-slicing --no-env-prune` | 1247.5 | UNSAFE | opt run_id `20260205-141109-2835`; witness: `.tmp/procurator/verify/frr_bug2_state_inconsistency/20260205-141109-2835/frr_bug2_state_inconsistency.bpl-witness.graphml`; base run_id `20260205-144530-d0ba`; witness: `.tmp/procurator/verify/frr_bug2_state_inconsistency/20260205-144530-d0ba/frr_bug2_state_inconsistency.bpl-witness.graphml` | interleaving |
| P4NIS bug1: forwarding sequence desync (NSDI) | `benchmarks/specs/bench/p4nis_bug1_forwarding_sequence_desync.prop` | `verify --wraparound off --use-spec-max-steps` | 77.7 | UNSAFE | `verify --wraparound off --use-spec-max-steps --no-slicing --no-env-prune` | 89.4 | UNSAFE | opt run_id `20260205-181513-b7a3`; witness: `.tmp/procurator/verify/p4nis_bug1_forwarding_sequence_desync/20260205-181513-b7a3/p4nis_bug1_forwarding_sequence_desync.bpl-witness.graphml`; opt sanity=FAIL(dsl_assert); base run_id `20260205-181642-56dd`; witness: `.tmp/procurator/verify/p4nis_bug1_forwarding_sequence_desync/20260205-181642-56dd/p4nis_bug1_forwarding_sequence_desync.bpl-witness.graphml`; base sanity=FAIL(dsl_assert) | interleaving |
| P4NIS bug2: tunnel state leakage (NSDI) | `benchmarks/specs/bench/p4nis_bug2_tunnel_state_leakage.prop` | `verify --wraparound off --use-spec-max-steps` | 61.0 | UNSAFE | `verify --wraparound off --use-spec-max-steps --no-slicing --no-env-prune` | 71.7 | UNSAFE | opt run_id `20260206-165824-85d9`; witness: `.tmp/procurator/verify/p4nis_bug2_tunnel_state_leakage/20260206-165824-85d9/p4nis_bug2_tunnel_state_leakage.bpl-witness.graphml`; base run_id `20260206-165921-4dce`; witness: `.tmp/procurator/verify/p4nis_bug2_tunnel_state_leakage/20260206-165921-4dce/p4nis_bug2_tunnel_state_leakage.bpl-witness.graphml` | functional |
| Gecko bug1: Timer Loss (NSDI) | `benchmarks/specs/bench/gecko_bug1_timer_loss.prop` | `verify --wraparound off --use-spec-max-steps --no-reg-debug --settings src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf` | 310.6 | UNSAFE | `verify --wraparound off --use-spec-max-steps --no-reg-debug --settings src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf --no-slicing --no-env-prune` | 405.6 | UNSAFE | opt run_id `20260207-121646-b0e5`; witness: `.tmp/procurator/verify/gecko_bug1_timer_loss/20260207-121646-b0e5/gecko_bug1_timer_loss.bpl-witness.graphml`; base run_id `20260207-122239-bc55`; witness: `.tmp/procurator/verify/gecko_bug1_timer_loss/20260207-122239-bc55/gecko_bug1_timer_loss.bpl-witness.graphml` | functional |
| Gecko bug2: Limited Concurrency Handling (NSDI) | `benchmarks/specs/bench/gecko_bug2_concurrency.prop` | `verify --wraparound off --use-spec-max-steps --no-reg-debug` | 346.1 | UNSAFE | `verify --wraparound off --use-spec-max-steps --no-reg-debug --no-slicing --no-env-prune` | 375.1 | UNSAFE | opt run_id `20260207-120301-5e8e`; witness: `.tmp/procurator/verify/gecko_bug2_concurrency/20260207-120301-5e8e/gecko_bug2_concurrency.bpl-witness.graphml`; base run_id `20260207-121004-28a9`; witness: `.tmp/procurator/verify/gecko_bug2_concurrency/20260207-121004-28a9/gecko_bug2_concurrency.bpl-witness.graphml` | interleaving |
| Gecko bug3: Improper Timer Initialization (NSDI) | `benchmarks/specs/bench/gecko_bug3_timer_init.prop` | `verify --wraparound off --use-spec-max-steps --no-reg-debug` | 36.5 | UNSAFE | `verify --wraparound off --use-spec-max-steps --no-reg-debug --no-slicing --no-env-prune` | 53.8 | UNSAFE | opt run_id `20260207-115958-23bb`; witness: `.tmp/procurator/verify/gecko_bug3_timer_init/20260207-115958-23bb/gecko_bug3_timer_init.bpl-witness.graphml`; base run_id `20260207-120122-f7bb`; witness: `.tmp/procurator/verify/gecko_bug3_timer_init/20260207-120122-f7bb/gecko_bug3_timer_init.bpl-witness.graphml` | implementation |
| P4xos: register access safety (NSDI) | `benchmarks/specs/bench/p4xos_bug.prop` | `verify --env max --wraparound off` | 197.1 | UNSAFE | `verify --env max --wraparound off --no-slicing --no-env-prune --settings src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g.epf` | - | N/A | opt run_id `20260205-185533-cfd6`; witness: `.tmp/procurator/verify/p4xos_bug/20260205-185533-cfd6/p4xos_bug.bpl-witness.graphml` | implementation |
| P4xos: forwarding correctness drop_flag (NSDI, old) | `benchmarks/specs/bench/p4xos_dropflag_bug.prop` | `verify --wraparound off --use-spec-max-steps --no-reg-debug` | 41.8 | UNSAFE | `verify --wraparound off --use-spec-max-steps --no-reg-debug --no-slicing --no-env-prune` | 49.0 | UNSAFE | opt run_id `20260206-201928-cae9`; witness: `.tmp/procurator/verify/p4xos_dropflag_bug/20260206-201928-cae9/p4xos_dropflag_bug.bpl-witness.graphml`; base run_id `20260206-205803-fa5c`; witness: `.tmp/procurator/verify/p4xos_dropflag_bug/20260206-205803-fa5c/p4xos_dropflag_bug.bpl-witness.graphml` | implementation |
| P4xos: majority quorum (NSDI) | `benchmarks/specs/bench/p4xos_majority_quorum_bug.prop` | `verify --wraparound off --use-spec-max-steps` | 1833.3 | UNSAFE | `verify --wraparound off --use-spec-max-steps --no-slicing --no-env-prune` | 1857.8 | UNSAFE | opt run_id `20260205-190747-c7cb`; witness: `.tmp/procurator/verify/p4xos_majority_quorum_bug/20260205-190747-c7cb/p4xos_majority_quorum_bug.bpl-witness.graphml`; base run_id `20260205-193856-c5bb`; witness: `.tmp/procurator/verify/p4xos_majority_quorum_bug/20260205-193856-c5bb/p4xos_majority_quorum_bug.bpl-witness.graphml` | interleaving |
| Cheetah: slot index collision (NSDI) | `benchmarks/specs/bench/cheetah_slot_index_collision_bug.prop` | `verify --wraparound off --use-spec-max-steps` | 123.7 | UNSAFE | `verify --wraparound off --use-spec-max-steps --no-slicing --no-env-prune` | 255.9 | UNSAFE | opt run_id `20260205-201024-e863`; witness: `.tmp/procurator/verify/cheetah_slot_index_collision_bug/20260205-201024-e863/cheetah_slot_index_collision_bug.bpl-witness.graphml`; base run_id `20260205-201230-d6a5`; witness: `.tmp/procurator/verify/cheetah_slot_index_collision_bug/20260205-201230-d6a5/cheetah_slot_index_collision_bug.bpl-witness.graphml` | implementation |
| NetLock: pkt_type domain | `benchmarks/specs/bench/netlock_pkt_type_bug.prop` | `verify --wraparound off --no-slicing-control-seeds` | 19.5 | UNSAFE | `verify --wraparound off --no-slicing-control-seeds --no-slicing --no-env-prune --settings src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g.epf` | 197.2 | UNSAFE | opt run_id `20260206-220921-bd76`; witness: `.tmp/procurator/verify/netlock_pkt_type_bug/20260206-220921-bd76/netlock_pkt_type_bug.bpl-witness.graphml`; base settings override: `src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g.epf`; base run_id `20260206-211318-a88b`; witness: `.tmp/procurator/verify/netlock_pkt_type_bug/20260206-211318-a88b/netlock_pkt_type_bug.bpl-witness.graphml` | implementation |
| NetLock: push_back length_in_server underflow | `benchmarks/specs/bench/netlock_pushback_length_in_server_underflow_bug.prop` | `verify --wraparound off --max-steps 3 --no-slicing-control-seeds` | 25.2 | UNSAFE | `verify --wraparound off --max-steps 3 --no-slicing-control-seeds --no-slicing --no-env-prune --settings src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf` | 250.3 | UNSAFE | opt run_id `20260207-013627-0974`; witness: `.tmp/procurator/verify/netlock_pushback_length_in_server_underflow_bug/20260207-013627-0974/netlock_pushback_length_in_server_underflow_bug.bpl-witness.graphml`; base settings override: `src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf`; base run_id `20260207-010827-ac64`; witness: `.tmp/procurator/verify/netlock_pushback_length_in_server_underflow_bug/20260207-010827-ac64/netlock_pushback_length_in_server_underflow_bug.bpl-witness.graphml` | implementation |
| NetLock: release counter underflow | `benchmarks/specs/bench/netlock_release_counter_underflow_bug.prop` | `verify --wraparound off --max-steps 3 --no-slicing-control-seeds` | 179.6 | UNSAFE | `verify --wraparound off --max-steps 3 --no-slicing-control-seeds --no-slicing --no-env-prune` | 263.1 | UNSAFE | opt run_id `20260206-023708-2c87`; witness: `.tmp/procurator/verify/netlock_release_counter_underflow_bug/20260206-023708-2c87/netlock_release_counter_underflow_bug.bpl-witness.graphml`; base run_id `20260205-204441-db35`; witness: `.tmp/procurator/verify/netlock_release_counter_underflow_bug/20260205-204441-db35/netlock_release_counter_underflow_bug.bpl-witness.graphml` | implementation |
| NetLock: release empty-queue head corruption | `benchmarks/specs/bench/netlock_release_empty_queue_head_bug.prop` | `verify --wraparound off --max-steps 3 --no-slicing-control-seeds` | 163.2 | UNSAFE | `verify --wraparound off --max-steps 3 --no-slicing-control-seeds --no-slicing --no-env-prune` | 241.3 | UNSAFE | opt run_id `20260206-024055-e37c`; witness: `.tmp/procurator/verify/netlock_release_empty_queue_head_bug/20260206-024055-e37c/netlock_release_empty_queue_head_bug.bpl-witness.graphml`; base run_id `20260205-210047-3a4e`; witness: `.tmp/procurator/verify/netlock_release_empty_queue_head_bug/20260205-210047-3a4e/netlock_release_empty_queue_head_bug.bpl-witness.graphml` | functional |
| NetLock: release empty_slots overflow | `benchmarks/specs/bench/netlock_release_empty_slots_overflow_bug.prop` | `verify --wraparound off --max-steps 3 --no-slicing-control-seeds --no-reg-debug --settings src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf` | 334.8 | UNSAFE | `verify --wraparound off --max-steps 3 --no-slicing-control-seeds --no-reg-debug --settings src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf --no-slicing --no-env-prune` | 411.3 | UNSAFE | opt run_id `20260206-170029-6949`; witness: `.tmp/procurator/verify/netlock_release_empty_slots_overflow_bug/20260206-170029-6949/netlock_release_empty_slots_overflow_bug.bpl-witness.graphml`; base run_id `20260206-170542-862a`; witness: `.tmp/procurator/verify/netlock_release_empty_slots_overflow_bug/20260206-170542-862a/netlock_release_empty_slots_overflow_bug.bpl-witness.graphml` | implementation |
| P4DB router: TTL expiry | `benchmarks/specs/bench/p4db_router_ttl_expiry_bug.prop` | `verify --wraparound off --max-steps 3 --no-slicing-control-seeds --no-reg-debug` | 59.4 | UNSAFE | `verify --wraparound off --max-steps 3 --no-slicing-control-seeds --no-reg-debug --no-slicing --no-env-prune` | 72.6 | UNSAFE | opt run_id `20260207-050518-bb35`; witness: `.tmp/procurator/verify/p4db_router_ttl_expiry_bug/20260207-050518-bb35/p4db_router_ttl_expiry_bug.bpl-witness.graphml`; base run_id `20260207-050612-3b0b`; witness: `.tmp/procurator/verify/p4db_router_ttl_expiry_bug/20260207-050612-3b0b/p4db_router_ttl_expiry_bug.bpl-witness.graphml` | implementation |
| P4DB router+damper: threshold off-by-one | `benchmarks/specs/bench/p4db_damper_threshold_off_by_one_bug.prop` | `verify --wraparound off --max-steps 3 --no-slicing-control-seeds --no-reg-debug` | 66.0 | UNSAFE | `verify --wraparound off --max-steps 3 --no-slicing-control-seeds --no-reg-debug --no-slicing --no-env-prune` | 79.9 | UNSAFE | opt run_id `20260207-043715-5cfd`; witness: `.tmp/procurator/verify/p4db_damper_threshold_off_by_one_bug/20260207-043715-5cfd/p4db_damper_threshold_off_by_one_bug.bpl-witness.graphml`; base run_id `20260207-043817-e513`; witness: `.tmp/procurator/verify/p4db_damper_threshold_off_by_one_bug/20260207-043817-e513/p4db_damper_threshold_off_by_one_bug.bpl-witness.graphml` | implementation |


<!-- E2E_ABLATIONS_END -->

## E2E Baseline Manual Recheck (2026-02-07)

- 逐条复核范围：`E2E Ablations` 表内 28 个 case（opt/base 双 run_id）。
- 复核结果：
  - `28/28` 的 `run_id` 目录存在；
  - `0` 条结果标签不一致（`USAGE` 的 `UNSAFE/SAFE/TIMEOUT` 与对应 `gemcutter.log` 一致）。
- 口径约束（本次保留基线、不删历史）：
  - `USAGE` 继续作为 E2E 基线真值表；
  - 若发现更晚 run 但属于不同实验口径（例如 toolchain timeout 明显更短的阶段采样 run）、或缺失 witness 产物、或性能无改进，则不覆盖基线行，仅在此记录。

| spec | baseline run_id（opt/base） | newer run（opt/base） | 处理结论 |
|---|---|---|---|
| `benchmarks/specs/bench/atp_bug.prop` | `20260207-023629-7563 / 20260207-023800-c853` | `20260207-135120-57db / 20260207-134901-f285` | 新 run 为短超时口径（`600/60s`），且 base 缺失 witness；保留基线。 |
| `benchmarks/specs/bench/distcache_cm34_write_bug.prop` | `20260207-014114-6184 / 20260207-012313-b30c` | `- / 20260207-012932-aff5` | 新 base run 缺失 witness，未作为可审计基线替换。 |
| `benchmarks/specs/bench/p4nis_bug1_forwarding_sequence_desync.prop` | `20260205-181513-b7a3 / 20260205-181642-56dd` | `20260207-053619-a873 / 20260207-053704-3900` | 新 run 为 `1800s` 口径采样；基线保持 `3600s` 口径可审计结果。 |
| `benchmarks/specs/bench/p4nis_bug2_tunnel_state_leakage.prop` | `20260206-165824-85d9 / 20260206-165921-4dce` | `20260207-054013-be83 / 20260207-054114-c2d9` | 新 run 为 `1800s` 口径采样；保留基线。 |
| `benchmarks/specs/bench/gecko_bug1_timer_loss.prop` | `20260207-121646-b0e5 / 20260207-122239-bc55` | `20260207-145625-d6ee / -` | 新 opt run 更慢（`OverallTime 352.6s > 310.6s`）且缺失 witness 文件；不替换。 |
| `benchmarks/specs/bench/p4xos_majority_quorum_bug.prop` | `20260205-190747-c7cb / 20260205-193856-c5bb` | `20260207-035243-e134 / -` | 新 opt run 同口径但无性能改进（`961.0s > 948.8s`）且缺失 witness 文件；基线不变。 |
| `benchmarks/specs/bench/netlock_pkt_type_bug.prop` | `20260206-220921-bd76 / 20260206-211318-a88b` | `- / 20260206-221206-b807` | 新 base run 为短超时口径（`600s`）且无 witness；不替换基线。 |

- 已是最新并采用当前优化参数（无需改写）的重点条目：
  - `gecko_bug2_concurrency`: `20260207-120301-5e8e / 20260207-121004-28a9`
  - `gecko_bug3_timer_init`: `20260207-115958-23bb / 20260207-120122-f7bb`
  - `fisslock_notification_cnt_wraparound_bug`: `20260207-123131-44d0 / 20260207-124213-5b92`

## Compile/Runtime Integrated Experiment (Current Version)

- Report document: `EXPERIMENT_STAGE_RUNTIME_CURRENT.md`
- Raw JSON: `.tmp/procurator/compile_runtime_integrated_all_systems.json`
- Compile profile JSONL: `.tmp/procurator/compile_runtime_integrated_all_systems.compile_profile.jsonl`

Generation command:

```bash
python3 dslc/bench/collect_compile_runtime_report.py \
  --results-json .tmp/procurator/e2e_ablations_1h_v2.json \
  --out-json .tmp/procurator/compile_runtime_integrated_all_systems.json \
  --out-md EXPERIMENT_STAGE_RUNTIME_CURRENT.md
```

Content includes:
- case-by-case runtime (`wall_s`/status) from current E2E checkpoint
- case-by-case compile stage times (frontend prune/translate + python harness emit + backend total)
- wraparound stage1/stage2/stage3 times reused from certified manifests
