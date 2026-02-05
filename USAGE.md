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

## Notes on `procurator_bad`

In **bounded** sequential harness runs (`--max-steps N`), DSL `global { assert { ... } }` checks are accumulated into a boolean flag `procurator_bad` and asserted once at the end of the unrolled run. Seeing `procurator_bad` in `.bpl` files or witness `VAL` dumps is expected (it is *not* a crash/error). An UNSAFE witness that sets this flag corresponds to a violated DSL global assertion.

## Notes on Wraparound vs One-step Overflow/Underflow

The integrated wraparound pipeline is meant for *long-prefix* counter flips (e.g., a 16/32-bit register reaching `MAX` and overflowing to `0`), where a plain bounded run would require an impractically long prefix.

Separately, some bugs are simple arithmetic overflow/underflow caused by missing guards/clamps (e.g., decrementing a counter at `0`), which can manifest in **one step** under bitvector semantics. These are expected to reproduce even with `--wraparound off` and are categorized as `implementation` (not `wraparound`) in the E2E table.

## Benchmark Summary (No-cache, 2026-01-30)

The runs below were executed with the current `./bin/procurator` CLI, which always creates a *fresh* per-run output directory under `.tmp/procurator/...` (no reuse of old `.bpl`, Ultimate HOME, or logs).

Common Ultimate settings:
- Ultimate binary: `.tmp/orphan-worktree-20260129-005608/UGemCutter-linux/Ultimate`
- Settings: `dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-no-por.epf`
- Timeout: `verify`: `300s` for small bugs, `600s` for DistCache; `wraparound`: `1200s` per stage
- Verify toolchain: `dslc/toolchain/ultimate/ReachSafety-Witness.xml`
- Wraparound toolchain: `dslc/toolchain/ultimate/ClosureCheck-ReachSafety.xml` (no witness printer; avoids Ultimate NPE on some SAFE closure checks)

<!-- E2E_ABLATIONS_START -->

## E2E Ablations (Auto-Generated)

Updated on 2026-02-05 with the latest E2E runs using Ultimate `/mnt/e/p4-verify/.tmp/orphan-worktree-20260129-005608/UGemCutter-linux/Ultimate`.

Category legend:
- `functional`: 功能类（功能/一致性性质被违反）
- `implementation`: 实现类（实现细节/边界处理错误；包含因缺少 guard/clamp 导致的溢出/下溢）
- `wraparound`: 变量翻转类（需要 wraparound 加速/证书的溢出相关 bug：ENTRY/CONFIRM=UNSAFE 且 CLOSURE=SAFE）
- `interleaving`: 交错类（并发/交错导致性质被违反）

| bug / benchmark | spec | opt cmd | opt time (s) | opt result | base cmd | base time (s) | base result | notes | category |
|---|---|---|---|---|---|---|---|---|---|
| NetChain wrap-around bug (NSDI) | `Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop` | `verify --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0` | 304.0 | entry UNSAFE; confirm UNSAFE; closure SAFE | `verify --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --no-slicing --no-env-prune` | 397.5 | entry UNSAFE; confirm UNSAFE; closure SAFE | opt run_id `20260205-110853-2a15`; stage times: entry 18.6s / confirm 72.4s / closure 213.0s; manifest: `.tmp/procurator/verify/netchain_wraparound_bug/20260205-110853-2a15/wraparound/target.00.s1_sequence_reg/wraparound.cegis.manifest.json`; opt confirm witness: `.tmp/procurator/verify/netchain_wraparound_bug/20260205-110853-2a15/wraparound/target.00.s1_sequence_reg/netchain_wraparound_bug.cegis.00.confirm.unroll3.bpl-witness.graphml`; base run_id `20260205-111405-ee5a`; stage times: entry 20.1s / confirm 89.6s / closure 287.8s; manifest: `.tmp/procurator/verify/netchain_wraparound_bug/20260205-111405-ee5a/wraparound/target.00.s1_sequence_reg/wraparound.cegis.manifest.json`; base confirm witness: `.tmp/procurator/verify/netchain_wraparound_bug/20260205-111405-ee5a/wraparound/target.00.s1_sequence_reg/netchain_wraparound_bug.cegis.00.confirm.unroll3.bpl-witness.graphml` | wraparound |
| ATP bound bug | `Procurator/argo/code/spec/bench/atp_bug.prop` | `verify --wraparound off` | 100.8 | UNSAFE | `verify --wraparound off --no-slicing --no-env-prune` | 87.2 | UNSAFE | opt run_id `20260205-123050-a4bb`; witness: `.tmp/procurator/verify/atp_bug/20260205-123050-a4bb/atp_bug.bpl-witness.graphml`; base run_id `20260205-123229-c4a2`; witness: `.tmp/procurator/verify/atp_bug/20260205-123229-c4a2/atp_bug.bpl-witness.graphml` | implementation |
| ATP count mismatch bug | `Procurator/argo/code/spec/bench/atp_count_mismatch_bug.prop` | `verify --wraparound off --use-spec-max-steps` | 164.2 | UNSAFE | `verify --wraparound off --use-spec-max-steps --no-slicing --no-env-prune` | 173.9 | UNSAFE | opt run_id `20260205-123433-755d`; witness: `.tmp/procurator/verify/atp_count_mismatch_bug/20260205-123433-755d/atp_count_mismatch_bug.bpl-witness.graphml`; base run_id `20260205-123715-782a`; witness: `.tmp/procurator/verify/atp_count_mismatch_bug/20260205-123715-782a/atp_count_mismatch_bug.bpl-witness.graphml` | functional |
| DistCache leaf pktloss clone/drop | `Procurator/argo/code/spec/bench/distcache_leaf_pktloss_clone_drop_bug.prop` | `verify (slicing)` | 162.3 | UNSAFE | `verify --no-slicing --no-env-prune` | 521.2 | UNSAFE | see per-run dirs under `.tmp/procurator/verify/` | functional |
| DistCache CM3/CM4 write wiring | `Procurator/argo/code/spec/bench/distcache_cm34_write_bug.prop` | `verify (slicing)` | 147.3 | UNSAFE | `verify --no-slicing --no-env-prune` | 563.9 | UNSAFE | see per-run dirs under `.tmp/procurator/verify/` | implementation |
| DistCache spine cache_frequency idx | `Procurator/argo/code/spec/bench/distcache_spine_cache_frequency_idx_bug.prop` | `verify (slicing)` | 65.1 | UNSAFE | `verify --no-slicing --no-env-prune` | 565.9 | TIMEOUT | see per-run dirs under `.tmp/procurator/verify/` | implementation |
| DistCache P2C spineload wrap-around bug | `Procurator/argo/code/spec/bench/distcache_p2c_spineload_wraparound_bug.prop` | `verify --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0` | 414.1 | entry UNSAFE; confirm UNSAFE; closure SAFE | `verify --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --no-slicing --no-env-prune` | 255.2 | entry UNSAFE; confirm UNSAFE; closure SAFE | opt run_id `20260205-114911-86b6`; stage times: entry 27.7s / confirm 297.6s / closure 88.8s; manifest: `.tmp/procurator/verify/distcache_p2c_spineload_wraparound_bug/20260205-114911-86b6/wraparound/target.00.clientTrack_partitionswitchIngress_spineload_reg/wraparound.cegis.manifest.json`; opt confirm witness: `.tmp/procurator/verify/distcache_p2c_spineload_wraparound_bug/20260205-114911-86b6/wraparound/target.00.clientTrack_partitionswitchIngress_spineload_reg/distcache_p2c_spineload_wraparound_bug.cegis.00.confirm.unroll3.bpl-witness.graphml`; base run_id `20260205-115611-3a6b`; stage times: entry 17.0s / confirm 156.6s / closure 81.6s; manifest: `.tmp/procurator/verify/distcache_p2c_spineload_wraparound_bug/20260205-115611-3a6b/wraparound/target.00.clientTrack_partitionswitchIngress_spineload_reg/wraparound.cegis.manifest.json`; base confirm witness: `.tmp/procurator/verify/distcache_p2c_spineload_wraparound_bug/20260205-115611-3a6b/wraparound/target.00.clientTrack_partitionswitchIngress_spineload_reg/distcache_p2c_spineload_wraparound_bug.cegis.00.confirm.unroll3.bpl-witness.graphml` | wraparound |
| DistCache P2C wrong-choice after overflow | `Procurator/argo/code/spec/bench/distcache_p2c_wraparound_bug.prop` | `verify --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0` | 236.3 | entry UNSAFE; confirm UNSAFE; closure SAFE | `verify --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --no-slicing --no-env-prune` | 252.2 | entry UNSAFE; confirm UNSAFE; closure SAFE | opt run_id `20260205-120106-6751`; stage times: entry 17.0s / confirm 139.0s / closure 80.2s; manifest: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260205-120106-6751/wraparound/target.00.clientTrack_partitionswitchIngress_leafload_reg/wraparound.cegis.manifest.json`; opt confirm witness: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260205-120106-6751/wraparound/target.00.clientTrack_partitionswitchIngress_leafload_reg/distcache_p2c_wraparound_bug.cegis.00.confirm.unroll3.bpl-witness.graphml`; base run_id `20260205-120508-f273`; stage times: entry 17.0s / confirm 144.8s / closure 90.4s; manifest: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260205-120508-f273/wraparound/target.00.clientTrack_partitionswitchIngress_leafload_reg/wraparound.cegis.manifest.json`; base confirm witness: `.tmp/procurator/verify/distcache_p2c_wraparound_bug/20260205-120508-f273/wraparound/target.00.clientTrack_partitionswitchIngress_leafload_reg/distcache_p2c_wraparound_bug.cegis.00.confirm.unroll3.bpl-witness.graphml` | wraparound |
| FissLock: premature TRANSFER after 8-bit notification_cnt wrap-around | `Procurator/argo/code/spec/bench/fisslock_notification_cnt_wraparound_bug.prop` | `verify --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0` | 546.3 | entry UNSAFE; confirm UNSAFE; closure SAFE | `verify --wraparound auto --wraparound-stage-order entry_confirm_closure --wraparound-max-targets 1 --wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0 --wraparound-closure-timeout-cap 0 --no-slicing --no-env-prune` | 535.9 | entry UNSAFE; confirm UNSAFE; closure SAFE | opt run_id `20260205-120946-5eb6`; stage times: entry 67.5s / confirm 339.6s / closure 139.1s; manifest: `.tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260205-120946-5eb6/wraparound/target.00.sw_IngressPipe_CounterTable_1_notification_cnt_1/wraparound.cegis.manifest.json`; opt confirm witness: `.tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260205-120946-5eb6/wraparound/target.00.sw_IngressPipe_CounterTable_1_notification_cnt_1/fisslock_notification_cnt_wraparound_bug.cegis.00.confirm.unroll3.bpl-witness.graphml`; base run_id `20260205-121903-c432`; stage times: entry 25.0s / confirm 357.3s / closure 153.6s; manifest: `.tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260205-121903-c432/wraparound/target.00.sw_IngressPipe_CounterTable_1_notification_cnt_1/wraparound.cegis.manifest.json`; base confirm witness: `.tmp/procurator/verify/fisslock_notification_cnt_wraparound_bug/20260205-121903-c432/wraparound/target.00.sw_IngressPipe_CounterTable_1_notification_cnt_1/fisslock_notification_cnt_wraparound_bug.cegis.00.confirm.unroll3.bpl-witness.graphml`; root cause: `notification_cnt` is `bit<8>` and wraps (255→0), making stale `hdr.lock.ncnt==0` indistinguishable and allowing TRANSFER (agent change) prematurely | wraparound |
| DDOSD: window label collision (NSDI) | `Procurator/argo/code/spec/bench/ddosd_window_label_collision_bug.prop` | `verify --wraparound off` | 104.7 | UNSAFE | - | - | N/A | run_id `20260204-002123-0e3d`; witness rerun: 101.5s; witness: `.tmp/procurator/verify/ddosd_window_label_collision_bug/20260204-002123-0e3d/ddosd_window_label_collision_bug.bpl-witness.graphml` | implementation |
| FRR bug1: unexpected mirror (NSDI) | `Procurator/argo/code/spec/bench/frr_bug1_unexpected_mirror.prop` | `verify --wraparound off --use-spec-max-steps (witness, noz3timeout)` | 32.6 | UNSAFE | - | - | N/A | run_id `20260204-005417-a972`; witness: `.tmp/procurator/verify/frr_bug1_unexpected_mirror/20260204-005417-a972/frr_bug1_unexpected_mirror.bpl-witness.graphml` | implementation |
| FRR bug2: state inconsistency (NSDI) | `Procurator/argo/code/spec/bench/frr_bug2_state_inconsistency.prop` | `verify --wraparound off --use-spec-max-steps (witness, noz3timeout)` | 32.4 | UNSAFE | - | - | N/A | run_id `20260204-020747-5d21`; witness: `.tmp/procurator/verify/frr_bug2_state_inconsistency/20260204-020747-5d21/frr_bug2_state_inconsistency.bpl-witness.graphml` | interleaving |
| P4NIS bug1: forwarding sequence desync (NSDI) | `Procurator/argo/code/spec/bench/p4nis_bug1_forwarding_sequence_desync.prop` | `verify --wraparound off --use-spec-max-steps (witness, noz3timeout)` | 28.0 | UNSAFE | - | - | N/A | run_id `20260204-005946-e8aa`; witness: `.tmp/procurator/verify/p4nis_bug1_forwarding_sequence_desync/20260204-005946-e8aa/p4nis_bug1_forwarding_sequence_desync.bpl-witness.graphml` | interleaving |
| P4NIS bug2: tunnel state leakage (NSDI) | `Procurator/argo/code/spec/bench/p4nis_bug2_tunnel_state_leakage.prop` | `verify --wraparound off --use-spec-max-steps (witness, noz3timeout)` | 93.4 | UNSAFE | - | - | N/A | run_id `20260204-014939-39bd`; witness: `.tmp/procurator/verify/p4nis_bug2_tunnel_state_leakage/20260204-014939-39bd/p4nis_bug2_tunnel_state_leakage.bpl-witness.graphml` | functional |
| Gecko bug1: Timer Loss (NSDI) | `Procurator/argo/code/spec/bench/gecko_bug1_timer_loss.prop` | `verify --wraparound auto --use-spec-max-steps (no wraparound targets; witness rerun)` | 516.5 | UNSAFE | - | - | N/A | run_id `20260203-072845-8b33`; witness rerun: 509.4s; witness: `.tmp/procurator/verify/gecko_bug1_timer_loss/20260203-072845-8b33/gecko_bug1_timer_loss.bpl-witness.graphml` | functional |
| Gecko bug2: Limited Concurrency Handling (NSDI) | `Procurator/argo/code/spec/bench/gecko_bug2_concurrency.prop` | `verify --wraparound off --use-spec-max-steps` | 177.6 | UNSAFE | - | - | N/A | run_id `20260203-213038-c121`; see `.tmp/procurator/verify/gecko_bug2_concurrency/20260203-213038-c121/` | interleaving |
| Gecko bug3: Improper Timer Initialization (NSDI) | `Procurator/argo/code/spec/bench/gecko_bug3_timer_init.prop` | `verify --wraparound off --use-spec-max-steps` | 44.6 | UNSAFE | - | - | N/A | run_id `20260203-212707-8618`; see `.tmp/procurator/verify/gecko_bug3_timer_init/20260203-212707-8618/` | implementation |
| P4xos: register access safety (NSDI) | `Procurator/argo/code/spec/bench/p4xos_bug.prop` | `verify --env max --wraparound off` | 34.4 | UNSAFE | - | - | N/A | run_id `20260203-214526-8ca6`; see `.tmp/procurator/verify/p4xos_bug/20260203-214526-8ca6/` | implementation |
| P4xos: forwarding correctness drop_flag (NSDI, old) | `Procurator/argo/code/spec/bench/p4xos_dropflag_bug.prop` | `verify --wraparound off --use-spec-max-steps` | 18.3 | UNSAFE | - | - | N/A | run_id `20260203-214823-8a73`; see `.tmp/procurator/verify/p4xos_dropflag_bug/20260203-214823-8a73/` | implementation |
| P4xos: majority quorum (NSDI) | `Procurator/argo/code/spec/bench/p4xos_majority_quorum_bug.prop` | `verify --wraparound off --use-spec-max-steps` | 67.3 | UNSAFE | - | - | N/A | run_id `20260203-214956-0cca`; see `.tmp/procurator/verify/p4xos_majority_quorum_bug/20260203-214956-0cca/` | interleaving |
| Cheetah: slot index collision (NSDI) | `Procurator/argo/code/spec/bench/cheetah_slot_index_collision_bug.prop` | `verify --wraparound off --use-spec-max-steps (witness, noz3timeout)` | 923.2 | UNSAFE | - | - | N/A | run_id `20260204-020924-0471`; witness: `.tmp/procurator/verify/cheetah_slot_index_collision_bug/20260204-020924-0471/cheetah_slot_index_collision_bug.bpl-witness.graphml` | implementation |
| NetLock: pkt_type domain | `Procurator/argo/code/spec/bench/netlock_pkt_type_bug.prop` | `verify --wraparound off` | 32.8 | UNSAFE | - | - | N/A | run_id `20260204-172803-2f72`; witness rerun: UNSAFE; witness: `.tmp/procurator/verify/netlock_pkt_type_bug/20260204-172803-2f72/netlock_pkt_type_bug.bpl-witness.graphml`; root cause: `ig_md.pkt_type` may be read uninitialized but is emitted in Mirror header and drives egress parse domain (`PKT_TYPE_NORMAL/MIRROR`) | implementation |
| NetLock: push_back length_in_server underflow | `Procurator/argo/code/spec/bench/netlock_pushback_length_in_server_underflow_bug.prop` | `verify --wraparound off --max-steps 3 --no-slicing-control-seeds` | 102.4 | UNSAFE | - | - | N/A | run_id `20260204-174026-9854`; witness rerun: UNSAFE; witness: `.tmp/procurator/verify/netlock_pushback_length_in_server_underflow_bug/20260204-174026-9854/netlock_pushback_length_in_server_underflow_bug.bpl-witness.graphml`; root cause: PUSH_BACK decrements `length_in_server` without guarding `>0`; robustness corner case (duplicate/retry) underflows to `2^32-1`; VAL shows `sw_slots_two_sides_register__dbg0=4294967295bv64` (expected `0bv64`) at `dsl_phase=1`; no wraparound pipeline needed (1-step underflow) | implementation |
| NetLock: release counter underflow | `Procurator/argo/code/spec/bench/netlock_release_counter_underflow_bug.prop` | `verify --wraparound off --max-steps 3 --no-slicing-control-seeds` | 64.7 | UNSAFE | - | - | N/A | run_id `20260204-174507-bcd9`; witness rerun: UNSAFE; witness: `.tmp/procurator/verify/netlock_release_counter_underflow_bug/20260204-174507-bcd9/netlock_release_counter_underflow_bug.bpl-witness.graphml`; root cause: RELEASE decrements packed counter without guarding `>0`; underflows; VAL shows `sw_shared_and_exclusive_count_register__dbg0=18446744069414584320bv64` (expected `0bv64`) at `dsl_phase=1`; stabilized by pinning `sw_ig_md.lock_id==0` to enable forall-init elimination (previous mismatch: TIMEOUT vs SAFE; run_ids `20260204-131646-94c8`/`20260204-132658-22d4`); no wraparound pipeline needed (1-step underflow) | implementation |
| NetLock: release empty-queue head corruption | `Procurator/argo/code/spec/bench/netlock_release_empty_queue_head_bug.prop` | `verify --wraparound off --max-steps 3 --no-slicing-control-seeds` | 102.4 | UNSAFE | - | - | N/A | run_id `20260204-174902-8b57`; witness rerun: UNSAFE; witness: `.tmp/procurator/verify/netlock_release_empty_queue_head_bug/20260204-174902-8b57/netlock_release_empty_queue_head_bug.bpl-witness.graphml`; root cause: `update_head_table.apply()` is unconditional even when queue is empty, so `head_register` advances; VAL shows `sw_head_register__dbg0=1bv32` (expected `0bv32`) at `dsl_phase=1` | functional |
| NetLock: release empty_slots overflow | `Procurator/argo/code/spec/bench/netlock_release_empty_slots_overflow_bug.prop` | `verify --wraparound off --max-steps 3 --no-slicing-control-seeds` | 52.8 | UNSAFE | - | - | N/A | run_id `20260204-175344-21c4`; witness rerun: UNSAFE; witness: `.tmp/procurator/verify/netlock_release_empty_slots_overflow_bug/20260204-175344-21c4/netlock_release_empty_slots_overflow_bug.bpl-witness.graphml`; root cause: RELEASE increments `empty_slots` without clamping at queue size; can overflow packed state; VAL shows `sw_slots_two_sides_register__dbg0=42949672960bv64` (expected `38654705664bv64`) at `dsl_phase=1`; previous attempt hit Z3 OOM (run_id `20260204-144020-8d3e`); no wraparound pipeline needed (1-step overflow) | implementation |
| P4DB router: TTL expiry | `Procurator/argo/code/spec/bench/p4db_router_ttl_expiry_bug.prop` | `verify --wraparound off --max-steps 3` | 12.3 | UNSAFE | `verify --boogie-harness sequential --wraparound off --max-steps 3 --no-slicing --no-env-prune` | 13.2 | UNSAFE | opt run_id `20260204-191616-ffa6`; opt witness: `.tmp/procurator/verify/p4db_router_ttl_expiry_bug/20260204-191616-ffa6/p4db_router_ttl_expiry_bug.bpl-witness.graphml`; base run_id `20260204-191118-39d7`; base witness: `.tmp/procurator/verify/p4db_router_ttl_expiry_bug/20260204-191118-39d7/p4db_router_ttl_expiry_bug.bpl-witness.graphml`; root cause: forwards packets where IPv4 TTL becomes `0` after decrement (common router invariant expects drop) | implementation |
| P4DB router+damper: threshold off-by-one | `Procurator/argo/code/spec/bench/p4db_damper_threshold_off_by_one_bug.prop` | `verify --wraparound off --max-steps 3` | 14.7 | UNSAFE | `verify --boogie-harness sequential --wraparound off --max-steps 3 --no-slicing --no-env-prune` | 16.8 | UNSAFE | opt run_id `20260204-162101-d6b1`; opt witness: `.tmp/procurator/verify/p4db_damper_threshold_off_by_one_bug/20260204-162101-d6b1/p4db_damper_threshold_off_by_one_bug.bpl-witness.graphml`; base run_id `20260204-191001-7af6`; base witness: `.tmp/procurator/verify/p4db_damper_threshold_off_by_one_bug/20260204-191001-7af6/p4db_damper_threshold_off_by_one_bug.bpl-witness.graphml`; root cause: damper check uses pre-increment value (`odb_metadata.damper`) so threshold=1 does not clear after first packet; VAL shows `sw_damper_register__dbg0=1bv16` (expected `0bv16`) at `dsl_phase=1` | implementation |


<!-- E2E_ABLATIONS_END -->
