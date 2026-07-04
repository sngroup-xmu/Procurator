# Procurator CLI reference

`./src/bin/procurator` is the only public command surface. The command delegates
to subcommands for compilation, verification, smoke checking, wraparound
analysis, and ablation runs.

```text
procurator compile
procurator verify
procurator smoke
procurator wraparound
procurator ablation
```

All commands accept `-h` or `--help` and print their local option set.

## Output policy

When no output path is supplied, Procurator creates a fresh run directory. It
does not reuse previous outputs as a cache.

```text
.tmp/procurator/compile/<spec>/<run_id>/
.tmp/procurator/verify/<spec>/<run_id>/
.tmp/procurator/wraparound/<spec>/<run_id>/
.tmp/procurator/ablation/<system>/<run_id>/
```

Use `--out`, `--work-dir`, `--log`, or `--out-dir` when a stable path is needed.

## `procurator compile`

`compile` translates a `.prop` spec to Boogie or Promela. Boogie is the default
backend.

```bash
./src/bin/procurator compile --spec <file.prop>
```

Common options:

| Option | Effect |
| --- | --- |
| `--spec <path>` | Selects the `.prop` input. Required. |
| `--backend boogie` | Emits a Boogie harness. This is the default. |
| `--backend promela` | Emits a Promela model. This path exists for compatibility. |
| `--out <path>` | Writes the backend output at a stable path. |
| `--work-dir <path>` | Stores P4B intermediate files. |
| `--p4b-bin <path>` | Uses a specific P4-to-Boogie translator. |
| `--p4c-translator-bin <path>` | Uses a specific translator for Promela imports. |
| `--clean` | Removes the Promela output directory before emitting a new Promela model. |
| `--env spec` | Applies DSL assumptions to external inputs. This is the default. |
| `--env max` | Makes external inputs fully nondeterministic. |
| `--no-prune` | Disables DAG slicing and environment-input pruning. |
| `--no-slicing-control-seeds` | Removes implicit forwarding, drop, clone, recirculate, and resubmit seeds. Use only when the property does not depend on topology-sensitive packet flow. |
| `--por` | Enables commutativity-based partial-order reduction. |
| `--boogie-harness concurrent` | Emits fork/atomic actor modeling. This is the default. |
| `--boogie-harness sequential` | Emits a single-thread nondeterministic scheduler. |
| `--no-two-stage` | Disables inferred ingress/egress two-stage scheduling. |
| `--max-steps <n>` | Adds a bounded bug-finding limit. `UNSAFE` remains useful; `SAFE` is only within the bound. |
| `--use-spec-max-steps` | Honors `global.max_steps` in the spec. |
| `--no-reg-debug` | Removes per-pass register snapshots from the generated harness. |
| `--skip-duplicated-fail-fast-global-asserts` | Omits duplicate register-mirror assertions inserted at write sites. |

Boogie compilation performs these steps:

```text
.prop parse
  -> P4 import translation by P4B
  -> environment and slicing analysis
  -> topology and actor harness generation
  -> Boogie file
```

## `procurator verify`

`verify` compiles the spec to Boogie and runs Ultimate/GemCutter when an
Ultimate executable is available.

```bash
./src/bin/procurator verify \
  --spec <file.prop> \
  --ultimate "$ULTIMATE"
```

Compilation options are shared with `compile` where applicable:

| Option | Effect |
| --- | --- |
| `--spec <path>` | Selects the `.prop` input. Required. |
| `--out <path>` | Writes the generated `.bpl` at a stable path. |
| `--work-dir <path>` | Stores P4B intermediate files. |
| `--p4b-bin <path>` | Uses a specific P4-to-Boogie translator. |
| `--env spec` | Applies DSL assumptions to external inputs. |
| `--env max` | Fully nondeterministic external inputs. |
| `--no-slicing` | Disables P4 slicing and pruning. |
| `--no-env-prune` | Keeps environment inputs even when slicing does not use them. |
| `--no-slicing-control-seeds` | Removes implicit packet-control seeds. |
| `--por` | Enables partial-order reduction. |
| `--no-por-guard` | Disables POR guards when POR is enabled. |
| `--boogie-harness concurrent` | Uses fork/atomic actor modeling. |
| `--boogie-harness sequential` | Uses a single-thread scheduler. |
| `--max-steps <n>` | Adds a bounded step limit. |
| `--use-spec-max-steps` | Uses `global.max_steps` from the spec. |
| `--no-reg-debug` | Removes register debug snapshots. |
| `--skip-duplicated-fail-fast-global-asserts` | Removes duplicate fail-fast register assertions. |

Solver options:

| Option | Effect |
| --- | --- |
| `--ultimate <path>` | Runs the selected Ultimate executable. If omitted and no default is found, `verify` compiles and skips the solver. |
| `--toolchain <xml>` | Selects an Ultimate toolchain XML. Basenames are resolved from the in-repo toolchain directory. |
| `--settings <epf>` | Selects an Ultimate settings EPF. Basenames are resolved from the in-repo settings directory. |
| `--ultimate-timeout-seconds <n>` | Sets the Ultimate toolchain timeout. Default: `900`. `0` disables the timeout. |
| `--ultimate-xmx-gb <n>` | Sets the Java heap. Default: `4`. |
| `--ultimate-home <path>` | Isolates Ultimate home and cache files. Default: inside the run directory. |
| `--log <path>` | Writes the solver log at a stable path. |
| `--ultimate-async` | Starts Ultimate in the background and returns immediately. |
| `--no-resource-limits` | Disables CPU and IO niceness wrappers. |
| `--no-witness-rerun` | Skips the second witness-printer run after an `UNSAFE` main result. |
| `--focused-direct auto` | Runs bounded DSL replay and focused direct prepasses before full solving. This is the default. |
| `--focused-direct off` | Runs only the full generated Boogie. |

Composition options:

| Option | Effect |
| --- | --- |
| `--compose` | Decomposes global assertions into smaller local specs. |
| `--compose-max-nodes <n>` | Limits nodes per decomposed property. Default: `2`. |
| `--compose-jobs <n>` | Runs decomposed properties in parallel. Default: `2`. |
| `--compose-local-inputs` | Allows direct external input for single-node sub-specs. |

Wraparound options integrated into `verify`:

| Option | Effect |
| --- | --- |
| `--wraparound auto` | Infers wraparound targets and runs CEGIS before ordinary GemCutter. This is the default. |
| `--wraparound off` | Skips wraparound acceleration. |
| `--wraparound force` | Runs wraparound CEGIS even when no candidate is inferred. |
| `--wraparound-max-targets <n>` | Limits target candidates. Default: `8`. |
| `--wraparound-confirm-unroll <n>` | Sets confirm unroll. `0` means automatic small-round default. |
| `--wraparound-max-confirm-unroll <n>` | Allows confirm unroll growth. `0` disables growth. |
| `--wraparound-max-iters <n>` | Sets refinement iterations per target. Default: `6`. |
| `--wraparound-closure-timeout-cap <n>` | Caps closure-check stage timeout. `0` uses the main timeout. |
| `--wraparound-stage-order <order>` | Chooses `entry_confirm_closure` or `entry_closure_confirm`. |
| `--wraparound-cegar-mode <mode>` | Chooses `legacy_closure_assumes` or `schedule_replay`. |
| `--wraparound-stop-after <stage>` | Stops after `entry`, `near_wrap`, or `closure` for staged debugging. |

Verification pipeline:

```text
.prop
  -> Boogie compile
  -> Boogie post-pass for solver robustness
  -> optional bounded DSL replay prepass
  -> optional focused-direct prepass
  -> optional wraparound CEGIS
  -> Ultimate/GemCutter main run
  -> optional witness rerun for UNSAFE
```

Exit-code convention:

```text
0  conclusive SAFE or compile-only success
1  conclusive UNSAFE
2  timeout, unknown, missing result, or inconclusive staged result
```

## `procurator smoke`

`smoke` checks generated Boogie structure. It does not run a solver.

```bash
./src/bin/procurator smoke \
  --bpl .tmp/procurator/tutorial/netchain_bug.bpl \
  --harness concurrent
```

Options:

| Option | Effect |
| --- | --- |
| `--bpl <path>` | Selects the generated Boogie file. Required. |
| `--harness concurrent` | Expects fork and atomic actor blocks. |
| `--harness sequential` | Expects a sequential scheduler harness. |

## `procurator wraparound`

`wraparound` exposes the explicit wraparound pipeline. Most users should start
with `procurator verify --wraparound auto`; this command is useful for staged
debugging.

```bash
./src/bin/procurator wraparound \
  --spec benchmarks/specs/bench/netchain_wraparound_bug.prop \
  --ultimate "$ULTIMATE"
```

Main options:

| Option | Effect |
| --- | --- |
| `--spec <path>` | Selects the `.prop` input. Required. |
| `--tag <name>` | Appends a tag to the spec stem when naming output files. |
| `--out-dir <path>` | Writes all stage files under a stable directory. |
| `--p4b-bin <path>` | Uses a specific P4B translator. |
| `--ultimate <path>` | Runs Ultimate. Without it, stage Boogie files are emitted but not solved. |
| `--ultimate-xmx-gb <n>` | Sets the Java heap for each Ultimate stage. Default: `4`. |
| `--toolchain <xml>` | Toolchain for bug-finding stages. |
| `--closure-toolchain <xml>` | Toolchain for closure checks. |
| `--settings <epf>` | Settings for bug-finding stages. |
| `--closure-settings <epf>` | Settings for closure checks. |
| `--timeout-seconds <n>` | Timeout per stage. Default: `1200`. |
| `--cegis` | Deprecated compatibility flag; CEGIS is already the default when `--ultimate` is provided. |
| `--legacy` | Uses the old non-iterative multi-stage pipeline. |
| `--cegis-max-iters <n>` | Limits CEGIS refinements. |
| `--wraparound-cegar-mode <mode>` | Chooses `legacy_closure_assumes` or `schedule_replay`. |
| `--wraparound-stop-after <stage>` | Emits an incremental manifest and stops. |
| `--stages <list>` | Selects legacy stages from `closure_check,pump,accel,confirm`. |
| `--soundness closure` | Requires `CLOSURE_CHECK == SAFE` before confirm. This is the default. |
| `--soundness cegis` | Requires a pump-stage repeatable +1 cycle before confirm. |
| `--soundness none` | Runs confirm as diagnostics without a soundness gate. |
| `--pump-reg <name>` | Selects the Boogie register to pump. |
| `--accel-regs <names>` | Selects registers to fast-forward. |
| `--index <n>` | Selects a register index. |
| `--confirm-unroll <n>` | Sets the confirm-stage unroll bound. Default: `3`. |
| `--pump-unroll <n>` | Sets the pump-stage loop unroll bound. `0` keeps the loop. |
| `--accel-unroll <n>` | Sets the accel-stage loop unroll bound. `0` keeps the loop. |
| `--no-slicing` | Disables P4 slicing and pruning in the base compile. |
| `--no-two-stage` | Disables inferred ingress/egress two-stage scheduling. |
| `--drop-dsl-asserts` | Deprecated no-op; the wraparound transform strips unrelated assertions itself. |
| `--proj-vars <names>` | Overrides projection variables. |
| `--allow-unsound-confirm` | Allows diagnostic confirm without closure proof. |
| `--no-resource-limits` | Disables CPU and IO niceness wrappers for stage solver runs. |

## `procurator ablation`

`ablation` runs a matrix over symmetry and assertion splitting. It is a
measurement command, not the normal user verification path.

```bash
./src/bin/procurator ablation \
  --spec <file.prop> \
  --ultimate "$ULTIMATE" \
  --toolchain ReachSafety.xml \
  --settings ReachSafety-32bit-GemCutter-ALL.epf \
  --p4b-bin src/p4b/source/build-host/backends/verify/p4c-translator
```

Options:

| Option | Effect |
| --- | --- |
| `--spec <path>` | Selects the `.prop` input. Required. |
| `--system <name>` | Labels output rows. Default: spec stem. |
| `--out-root <path>` | Writes results under a stable directory. |
| `--ultimate <path>` | Runs the selected Ultimate executable. Required. |
| `--toolchain <xml>` | Selects the Ultimate toolchain XML. Required. |
| `--settings <epf>` | Selects the Ultimate settings EPF. Required. |
| `--p4b-bin <path>` | Uses a specific P4-to-Boogie translator. Required. |
| `--timeout-s <n>` | Timeout per run. Default: `1200`. |
| `--env spec|max` | Selects environment input mode. |
| `--max-nodes <n>` | Limits nodes per decomposed property. |
| `--no-resource-limits` | Disables process niceness wrappers. |

## Ultimate toolchains and settings

`--toolchain` selects an XML file. `--settings` selects an EPF file. Procurator
accepts either full paths or known basenames.

Toolchains:

```text
ReachSafety.xml
ReachSafety-Witness.xml
ClosureCheck-ReachSafety.xml
ReachSafety-BuchiAutomizer.xml
ReachSafety-BuchiAutomizer-Witness.xml
ReachSafety-Transformed-Witness.xml
```

Common GemCutter settings:

```text
ReachSafety-32bit-GemCutter-ALL.epf
ReachSafety-32bit-GemCutter-ALL-no-por.epf
ReachSafety-32bit-GemCutter-ALL-4g.epf
ReachSafety-32bit-GemCutter-ALL-8g.epf
ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf
ReachSafety-32bit-GemCutter-ALL-witness.epf
```

Selection guidance:

- Start with `ReachSafety.xml` and `ReachSafety-32bit-GemCutter-ALL.epf`.
- Use witness settings only when witness generation is needed on the main run.
  `verify` can run witness generation as a second pass after `UNSAFE`.
- Use `smallblocks` settings when large blocks cause solver memory pressure.
- Use `no-por` settings when POR changes the debugging surface.
- Increase `--ultimate-xmx-gb` and choose 8g or 12g settings only on machines
  with enough memory.
- Keep timeouts finite. A timeout is inconclusive, not evidence of safety.

## P4B translator resolution

For P4 imports, Procurator needs a P4-to-Boogie translator. It resolves one of:

```text
src/p4b/source/build-host/backends/verify/p4c-translator
src/p4b/source/build-host/p4c-translator
src/dslc/toolchain/p4b_docker.sh
```

Pass `--p4b-bin` when the translator is built somewhere else.
