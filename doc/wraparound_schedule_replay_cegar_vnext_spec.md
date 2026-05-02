# Wraparound Schedule-Replay CEGAR vNext Implementation Spec

Status: draft for implementation review

Date: 2026-04-28

Scope: replace the current witness-shape-only wraparound CEGIS refinement with the paper-aligned three-stage schedule-replay CEGAR loop, while keeping existing benchmark behavior reproducible during migration.

Primary code areas:

- `dslc/workflows/wraparound_cegis.py`
- `dslc/transform/wraparound*.py`
- `dslc/toolchain/ultimate_witness.py`
- `dslc/analysis/wraparound_candidates.py`
- `dslc/cli/gemcutter.py`
- `dslc/cli/wraparound.py`
- `dslc/tests/test_wraparound_*`

Reference basis:

- Paper section 6, "Backend Verifier": three-stage wraparound acceleration.
- Paper Figure 9: Entry Check, Near-wrap Check, Closure Check.
- Paper Appendix C.1: near-wrap value computation.
- Paper Appendix C.2 / Lemma C.1: reachability of near-wrap state from a closed update schedule.
- Current implementation notes in `AGENTS.md`, especially the existing `ENTRY/CONFIRM/CLOSURE` integration and closure-only CEGIS policy.

## 1. Problem Statement

The current repository implementation already has a practical wraparound pipeline:

1. `ENTRY_CHECK` asks whether the base harness can reach the pump cutpoint.
2. `CONFIRM` fast-forwards the target register to a wrap boundary and searches for a short bug suffix.
3. `CLOSURE_CHECK` tries to prove that the pump is repeatable.
4. If closure fails, refinement mostly adds witness-derived "shape" assumptions to the closure obligation only.

This is useful, but it is not the exact CEGAR loop described in the paper. The paper's loop is schedule-oriented:

1. `Entry Check` synthesizes an update schedule `sche`, i.e. an actor-order array such as `[env, s1, s2]` that updates the target register slot under the current projection.
2. `Near-wrap Check` reuses that actor order at a near-wrap state and asks whether the original property can fail quickly.
3. `Closure Check` certifies that the actor-order schedule can be replayed repeatedly under a projection that captures the required control/data predicates and mailbox state. If closure is `UNSAFE`, the failing schedule/projection pair is blocked and `Entry Check` is rerun to synthesize another schedule.

The key change is therefore:

Current refinement:

```text
ENTRY once -> CONFIRM once -> refine CLOSURE assumptions only
```

Target refinement:

```text
ENTRY synthesize schedule sche
  -> NEAR_WRAP confirm suffix for sche
  -> CLOSURE certify sche
     -> SAFE: certified wraparound bug
     -> UNSAFE: block sche and rerun ENTRY
     -> UNKNOWN: stop, no evidence-backed refinement
```

The new implementation must preserve this soundness contract:

```text
Report certified wraparound UNSAFE only if:
  ENTRY is UNSAFE and yields actor-order schedule sche
  NEAR_WRAP/CONFIRM is UNSAFE under sche
  CLOSURE is SAFE for sche
```

If any stage is missing, unknown, or contradicted, the pipeline may report an uncertified diagnostic artifact or fall back to ordinary verification, but it must not label the result as a certified wraparound bug.

## 2. Design Goals

1. Align implementation semantics with the paper.
   `Closure Check` failures must produce schedule blockers and resynthesize schedules through `Entry Check`, not only add closure-side witness shape assumptions.

2. Preserve existing working cases during migration.
   Existing `netchain_wraparound_bug`, `distcache_p2c_wraparound_bug`, `distcache_p2c_spineload_wraparound_bug`, and `fisslock_notification_cnt_wraparound_bug` should still certify after the migration. The old closure-assumption mode may remain behind a compatibility flag until the schedule-replay mode is stable.

3. Keep CEGAR evidence-backed.
   Refinements may be generated only from concrete `UNSAFE` witnesses. `UNKNOWN` and timeout are not evidence and must not trigger heuristic refinements by default.

4. Avoid false certified bugs.
   The pipeline can under-approximate schedules or environment shapes for bug finding, but a certified result must include the entry witness, near-wrap witness, and closure proof for the same schedule identity.

5. Make artifacts auditable.
   The manifest must describe the synthesized actor-order schedule, target slots, step delta, projection, blockers, stage results, and exact BPL/log/witness paths.

6. Prepare for broader actor-interaction bug discovery.
   The projection representation should be general enough for V1MODEL and TNA actor interactions such as recirculation, mirroring, cloning, multicast, digest-like notification, register index reuse, and cross-node forwarding.

## 3. Non-goals For This First Change

1. Do not replace Ultimate/GemCutter.
   The new CEGAR loop continues to call Ultimate on generated Boogie stages.

2. Do not prove all schedules absent when no certified bug is found.
   If schedule enumeration is exhausted under our blockers, or Ultimate returns `UNKNOWN`, the result is diagnostic/fallback, not global safety.

3. Do not solve arbitrary non-monotonic acceleration.
   This spec targets counter-like register updates with nonzero constant or meta-derived affine step deltas already discoverable from current P4B metadata.

4. Do not rewrite the entire harness.
   The implementation should add explicit actor-order instrumentation/replay constraints around the current sequential deterministic harness first. Concurrent harness support can come later.

## 4. Terminology

Target candidate:

A wraparound candidate from `infer_wraparound_candidates`, including:

- `pump_reg`
- `accel_regs`
- `index_expr` / `index_value`
- `step_delta`
- `step_op`
- `proj_vars`
- `cutpoint_cond`

Target slot vector:

The concrete register cells that must progress together:

```text
R = [pump_reg[index], accel_reg_1[index], ..., accel_reg_n[index]]
```

Actor schedule `sche`:

A finite, ordered array of actors extracted from an `Entry Check` witness. This is the only certified schedule object:

```text
sche = [actor_0, actor_1, ..., actor_k]
```

For example:

```text
sche = [env, s1, s2]
```

Fine-grained packet events, table outcomes, mailbox dequeues, source queue choices, parser states, and action names are not part of `sche`. They must not be smuggled into the actor array or treated as the schedule identity.

Why this is enough:

The closure obligation is not "replay this whole witness log". It is:

```text
given the same projection pi and a no-wrap target value,
execute the actor order sche under the original harness semantics,
prove the net target update and prove pi is preserved.
```

Thus the packet/event facts matter only if replay depends on them. In that case they belong in the projection `pi` and must be proved preserved by Closure, or Closure must universally discharge the residual choice as irrelevant. If they are merely witness/path/environment facts, they may be recorded as `conditions` for diagnosis, but a result depending on them is not certified.

Implementation note:

The current manifest may include `phases` and `reactions` for audit/debugging because the sequential harness exposes deterministic phase bodies. These fields are not the certified `sche`; they are not part of the core schedule identity and must not be required by the proof. The certified core is:

```text
schedule.actors == sche
schedule.projection == closure-proved pi
schedule.conditions == []
```

This actor-only encoding is valid only if one of the following holds for every step:

1. actor name plus the harness state in `pi(s)` uniquely determines the enabled step and delivery/dequeue semantics;
2. any remaining choice is fixed by the projection `pi(s)`;
3. `Closure Check` proves the step for all remaining nondeterminism, so the hidden choice is immaterial to enabledness, delivery, target update, and the post-projection.

Compatibility with the paper proof:

The paper describes a concrete update schedule with implied packet deliveries and control outcomes. In this implementation spec, `sche` is the actor-order representation of that schedule, while the implied deliveries/control outcomes are represented by projection predicates or by universal closure over residual nondeterminism. Equivalently:

```text
paper schedule = actor order + semantic replay obligations
this spec sche = actor-order array only
this spec pi(s) includes delivery/control/mailbox facts needed for replay,
  or closure proves those facts irrelevant
```

If some delivery/control fact is not in `pi(s)`, Closure Check must either prove it irrelevant or return a counterexample that drives projection refinement/blocking. A certified result may not rely on an unproved assumption about packet delivery, table/action choice, or mailbox dequeue order.

Projection `pi(s)`:

The certificate projection used by closure. It contains the stable state needed to make the actor schedule `sche` replayable, including:

- scheduler phase
- mailbox/worklist/inbox counts, and selected mailbox packet snapshots when the cutpoint is after env injection or when a mailbox is nonempty
- env-generated packet shape when the cutpoint is before env injection
- control predicates obtained from control/data dependence analysis
- target index landing facts

The intended MVP cutpoint is before env injection. For this cutpoint, mailboxes should usually be empty and projection can remain compact:

```text
procurator_phase == 0
s1_inbox_count == 0
s2_inbox_count == 0
...
env pump packet shape is fixed by env constraints
```

If a later benchmark uses a cutpoint after env injection, the projection must include the relevant mailbox cell contents, at least the header/meta fields that control parsing, table selection, forwarding, and target index landing.

Projection coverage obligation:

For a certified result, `pi` is not merely a useful list of predicates. It is a proof obligation. It must be strong enough that, for every state satisfying the cutpoint, `pi(s) == pi0`, and `NoWrap` for the target slots, replaying `sche` in the original harness semantics is executable and all residual nondeterminism is irrelevant to the following facts:

1. the same actor steps are enabled;
2. the packet/mailbox/worklist choices needed by `sche` are reproduced through `pi`, or any alternative choice is proven immaterial;
3. packet delivery, drop, recirculation, clone, mirror, multicast, and forwarding decisions relevant to the next actor are reproduced or proven immaterial;
4. target index landing is the same, or the target slot vector explicitly models and proves the allowed index evolution;
5. every target slot advances by the declared nonzero `step_delta`;
6. the post-state satisfies the cutpoint condition and `pi(post) == pi0`;
7. the near-wrap first step and violation suffix do not observe unprojected state, unless that state is separately initialized to an Entry/Closure-compatible value and validated.

This is especially important for mailbox/worklist state. If the cutpoint is before env injection and queues are empty, count predicates may be enough. If the cutpoint is after injection or a queue is nonempty, preserving only the count is not enough: `pi` must also cover the selected cell validity/order/dequeue source and all packet/header/meta fields that affect parsing, control flow, target index, forwarding, and delivery.

`conditions`:

The manifest may also include `schedule.conditions`. These are witness-derived replay/profile predicates synthesized from an `UNSAFE` near-wrap witness or other diagnostic sources. They are useful for debugging why a closure attempt is hard or conditional, but they are not proof obligations unless they are moved into `projection` and Closure proves them preserved.

Certification rule:

```text
schedule.conditions must be empty for certified schedule-replay UNSAFE.
```

If Closure is `SAFE` only under nonempty `conditions`, the attempt is a conditional diagnostic and integrated `verify --wraparound auto` must fall back to ordinary GemCutter/direct verification.

Core closure condition:

```text
Closure(sche, pi, step) holds iff:
  for all states s satisfying cutpoint(s), pi(s) == pi0, and NoWrap(R(s), step),
  executing exactly the actor order sche yields s'
  such that cutpoint(s'), pi(s') == pi0, and R(s') == R(s) + step.
```

This is the essential certificate. Fine-grained events are important only insofar as dependence analysis says they must appear in `pi(s)`.

Step and no-wrap obligations:

- `step_delta != 0`.
- `0 < abs(step_delta) < W`, where `W = 2^bitwidth`.
- `step_delta` is interpreted as a signed mathematical integer delta, not an arbitrary bitvector residue.
- Entry must not infer `step_delta` from an already-wrapped update unless metadata provides the affine delta and Closure reproves it.
- For multiple target slots, Closure conjoins `NoWrap` and the declared net effect for every slot.
- `NoWrap_d(x)` must be precise:
  - if `d > 0`, then `x <= W - 1 - d`;
  - if `d < 0`, then `x >= -d`.
- Closure must re-establish the cutpoint/scheduler mode required to apply the induction again.

Near-wrap value:

For a `w`-bit register, modulus `W = 2^w`, initial value `R0`, and nonzero integer step `d`, choose:

```text
if d > 0:
  n_star = floor(((W - 1) - R0) / d)
  R_star = R0 + n_star * d
  R_star in [W - d, W - 1]

if d < 0:
  n_star = floor(R0 / (-d))
  R_star = R0 + n_star * d
  R_star in [0, -d - 1]
```

One more replay of `sche` crosses the modulo boundary.

Schedule blocker:

A Boogie expression inserted into the next `Entry Check` to prevent rediscovering the same non-closed actor-order schedule/projection pair:

```text
not actor_schedule_signature_sigma
```

The signature should start from the actor array and the projection snapshot, not from fine-grained event logs.

## 5. Target Three-stage Algorithm

The new loop should be implemented as an explicit schedule CEGAR engine.

Pseudo-code:

```python
blockers = []

for iter in range(max_iters):
    entry = run_entry_check(candidate, blockers)
    if entry.result != UNSAFE:
        return fallback_or_uncertified(entry)

    sche = extract_update_schedule(entry.witness, candidate)
    if not sche.valid:
        blockers.append(make_malformed_schedule_blocker(entry.witness))
        continue

    near = run_near_wrap_check(candidate, sche)
    if near.result == UNSAFE:
        closure = run_closure_check(candidate, sche)
        if closure.result == SAFE:
            return certified_unsafe(entry, near, closure, sche)
        if closure.result == UNSAFE:
            blockers.append(make_schedule_blocker(sche, closure.witness))
            continue
        return uncertified_unknown(entry, near, closure, sche)

    if near.result == SAFE:
        # Paper-compatible default: acceleration did not expose a bug for this slot/schedule.
        return fallback_direct_or_no_accel(entry, near, sche)

    # UNKNOWN or timeout.
    return uncertified_unknown(entry, near, None, sche)
```

Important behavior:

- `Entry Check` is rerun after a closure counterexample.
- `Near-wrap Check` is the paper's Stage 2. It is equivalent to the current `CONFIRM`, but it must be tied to the extracted actor-order schedule identity.
- `Closure Check` is Stage 3 and must prove the same actor order under the selected projection, not a looser ad hoc shape.
- `UNKNOWN` does not refine.
- Any non-certified outcome falls back to ordinary GemCutter direct checking in `procurator verify`, so bugs that do not match the wraparound acceleration pattern remain covered by the normal backend.
- Existing closure-only mode can remain as `legacy_closure_assumes` while this mode lands.

Near-wrap certification compatibility:

A Near-wrap `UNSAFE` witness certifies only if its initial state is compatible with the pumped state guaranteed by Closure. The initial state may set the target slots to `R_star` and assume `pi == pi0`, but any unprojected variable observed before the assertion violation must either be:

- irrelevant by dependency/support analysis;
- fixed to an Entry-compatible value and included in `pi`; or
- validated by an explicit replay/compatibility check.

Otherwise the Near-wrap witness is an uncertified diagnostic, and integrated `verify --wraparound auto` must continue to ordinary GemCutter direct checking.

## 5.1 Direct GemCutter Fallback Contract

Wraparound acceleration is an optimization for deep counter-like traces, not a replacement for the backend verifier.

`procurator verify --wraparound auto` must therefore obey this contract:

```text
try schedule-replay wraparound acceleration first
if it returns a certified wraparound UNSAFE:
  report UNSAFE and emit the certified manifest/witness
else:
  run the ordinary compiled base .bpl through GemCutter
```

Fallback must happen for all of these cases:

- no wraparound candidate is inferred
- candidate metadata is incomplete
- `Entry Check` is `SAFE`, `UNKNOWN`, timeout, or cannot extract an actor schedule
- schedule is malformed, unsupported, or cannot be linked to stable actor boundaries under the chosen projection
- `Near-wrap Check` is `SAFE`, `UNKNOWN`, or timeout
- `Closure Check` is `UNKNOWN` or timeout
- `Closure Check` is `UNSAFE` but blocker budget is exhausted
- CEGAR reaches `max_iters` without a certified schedule
- all candidate schedules are blocked or duplicate-blocker detection fires
- unsupported actor feature cannot be projected soundly, such as post-env cutpoint with unavailable mailbox packet snapshots, unfixed bag dequeue choices, or clone/mirror/recirculation metadata not represented in `pi`
- manifest validation fails, including mismatched `schedule_id` or `base_bpl_sha256`
- schedule replay mode raises an implementation error in `auto` mode

`--wraparound force` may still fail fast for debugging if the user explicitly asked to force wraparound, but `auto` must never suppress the normal GemCutter run. This is required because many bugs are implementation, functional, or interleaving bugs that do not require a near-wrap prefix.

The ordinary fallback run uses exactly the base BPL compiled before acceleration, with the user's original slicing/env-prune/harness/toolchain/settings choices. The wraparound stage may emit diagnostic artifacts, but those artifacts must not add assumptions to the fallback GemCutter run.

Final result policy:

The schedule-replay pipeline may return certified `UNSAFE` only for the triple:

```text
ENTRY=UNSAFE
NEAR_WRAP/CONFIRM=UNSAFE
CLOSURE=SAFE
same schedule_id
same base_bpl_sha256
schedule.conditions == []
near-wrap initial state compatible with the closure-reachable pumped state
```

Every other acceleration outcome is non-decisive. In integrated `verify --wraparound auto`, a non-decisive acceleration result must fall back to ordinary GemCutter direct checking on the unaccelerated base BPL. If direct checking is not run or returns `UNKNOWN`/timeout/error, the final result must be `UNKNOWN`/uncertified rather than `SAFE`.

## 6. Stage Semantics

### 6.1 Entry Check

Purpose:

Find a concrete short execution that updates the target register slot vector by a nonzero step.

Instrumentation requirements:

1. Snapshot target slots before and after each actor reaction:

```boogie
wa_R_pre := R[index];
...
wa_R_post := R[index];
```

2. Detect progress:

```boogie
wa_step := wa_R_post - wa_R_pre;
wa_progress := wa_step != 0bvW;
```

3. Prefer step consistency across all target slots:

```boogie
forall target slot Ri:
  Ri_post - Ri_pre == wa_step
```

In implementation, avoid quantifiers and generate explicit conjunctions for the finite target slot vector.

4. Emit actor-order trace variables at stable points:

```boogie
wa_sched_len
wa_sched_actor_0
...
```

The certified schedule ghosts are actor identities only. Harness phases, if emitted, are debug/audit metadata and may help reconstruct where the actor step came from, but they are not `sche`. Any information needed to make the actor step executable, such as mailbox counts, env shape, control/data predicates, packet snapshots, or deterministic scheduler mode, must be emitted and checked as projection data. If explicit arrays are inconvenient in Boogie, use scalar ghosts up to a bounded max schedule length.

5. Trigger an `UNSAFE` result only when progress is found and no blocker matches:

```boogie
if (wa_progress && !blocked_by_previous_schedules) {
  call __wraparound_entry_error();
}
```

Output:

- `entry_check.bpl`
- `entry_check.log`
- `entry_check.bpl-witness.graphml`
- parsed `ActorSchedule`
- inferred `step_delta`
- entry projection snapshot
- target index value(s)

Extraction requirements:

Implement a parser that reconstructs `ActorSchedule` from explicit actor/phase ghost variables and reconstructs the projection snapshot from dependency-selected projection variables. Do not rely on brittle sourcecode text matching unless as a fallback.

### 6.2 Near-wrap Check

Purpose:

Given `sche`, initialize the target slot vector to the computed near-wrap value and ask whether the original assertion can fail in a short suffix under the same actor replay pattern.

Relationship to current implementation:

This is the current `CONFIRM` stage, but the new version must accept a schedule object and optional replay constraints.

Inputs:

- candidate
- schedule `sche`
- target slot vector
- bitwidth `w`
- step `d`
- initial value `R0` from entry, defaulting to zero if the benchmark's initial register state is known to be zero
- suffix unroll bound

Boogie transformation:

1. At the cutpoint, set each target slot to `R_star`.
2. Reassert entry-derived projection facts needed to replay the first wrap step.
3. Constrain the first wrap step to the actor order `sche` and assert the projection snapshot at the cutpoint. The suffix after the wrap may either:
   - remain schedule-constrained for strict paper mode, or
   - be released to full harness semantics after the first wrap step for bug-finding mode.

Default for this change:

- First wrap step is actor-order constrained and projection-constrained.
- Remaining suffix uses the current full semantics unless `--wraparound-strict-replay` is set.

Output:

- `near_wrap.bpl` or compatibility name `confirm.unrollN.bpl`
- log
- witness if `UNSAFE`

Result handling:

- `UNSAFE`: proceed to `Closure Check`.
- `SAFE`: paper-compatible fallback for this slot/schedule; do not report certified bug.
- `UNKNOWN`: stop without refinement unless the user increases timeout/unroll.

Certification compatibility:

The `UNSAFE` witness must be checked against the projection support. If the witness uses an initial unprojected value before the violation, schedule mode must either expand `pi` and rerun the triple or report an uncertified diagnostic and fall back. This prevents stitching a valid pumped prefix to a suffix whose first state was chosen outside the closed projection.

### 6.3 Closure Check

Purpose:

Prove that the actor schedule `sche` is replayable for arbitrary no-wrap target values and makes the target slot vector progress by the same step while preserving projection.

Inputs:

- candidate
- schedule `sche`
- projection `pi`
- step `d`
- target slot vector

Boogie transformation:

1. Replace target values with symbolic `wa_R0`:

```boogie
havoc wa_R0;
assume NoWrap_d(wa_R0);
R_i[index] := wa_R0;
```

2. Restore schedule-entry projection snapshot from `sche`:

```boogie
assume pi(state) == pi_sigma_entry;
```

3. Execute exactly one round of `sche` by forcing the scheduler to pick the recorded actor order. The projection assumptions, not the schedule object, constrain mailbox state, env-generated packet shape, and control/data-dependent predicates.

4. Assert progress:

```boogie
R_i[index] == wa_R0 + d
```

5. Assert closure:

```boogie
pi(state_after) == pi_sigma_entry
```

6. Assert cutpoint re-entry if the candidate has a cutpoint condition:

```boogie
cutpoint_cond(state_after)
```

Result handling:

- `SAFE`: actor-order schedule is certified repeatable under the projection; combine with Near-wrap `UNSAFE` to report certified bug.
- `UNSAFE`: extract closure counterexample and generate a schedule blocker; rerun `Entry Check`.
- `UNKNOWN`: stop; do not refine.

Closure `SAFE` means the generated Boogie obligation has proven a universal one-round certificate: for all states satisfying the cutpoint, projection snapshot, and `NoWrap` for every target slot, executing exactly `sche` under the original harness semantics returns to the cutpoint, preserves `pi`, and advances the target slot vector by `step_delta`. It must not rely on assumptions that force impossible table outcomes, packet deliveries, or queue states.

## 7. Schedule And Projection Representation

Add a new module, preferably:

```text
dslc/workflows/wraparound_schedule.py
```

Dataclasses:

```python
@dataclass(frozen=True)
class ProjectionPredicate:
    lhs: str
    rhs: str
    kind: str  # scheduler, mailbox, env, control_dep, data_dep, target_index
    source: str  # dependency_analysis, witness_snapshot, inferred

@dataclass(frozen=True)
class ActorSchedule:
    schedule_id: str
    candidate_id: str
    actors: tuple[str, ...]
    phases: tuple[int, ...]  # optional audit/debug metadata; not certified sche
    reactions: tuple[str, ...]  # optional audit/debug metadata; not certified sche
    target_regs: tuple[str, ...]
    index_value: int
    step_delta: int
    bitwidth: int
    projection: tuple[ProjectionPredicate, ...]
    entry_witness: str
    base_bpl_sha256: str
    conditions: tuple[ProjectionPredicate, ...] = ()  # diagnostic only; must be empty for certification

@dataclass(frozen=True)
class ScheduleBlocker:
    blocker_id: str
    schedule_id: str
    reason: str  # closure_unsafe, malformed, duplicate
    expr: str
    actors: tuple[str, ...]
    projection: tuple[ProjectionPredicate, ...]
```

Schedule identity:

Compute `schedule_id` as a stable hash over:

- candidate target register(s)
- target index
- step delta
- ordered actor array
- selected projection predicate names and values
- base BPL hash

Do not include absolute output directory paths in the hash.
Do not include `reactions`, `phases`, witness-derived `conditions`, or fine-grained event logs in the certified schedule identity.

## 8. Projection: What To Preserve

The actor schedule is intentionally small. Replay soundness comes from the projection. The projection must be strong enough that executing the actor array again consumes/produces the right mailbox state and follows a path with the same net update effect, but it should not preserve unrelated packet payload.

Start with these projection classes:

1. Scheduler/cutpoint:

- `procurator_phase` per step when deterministic scheduler is present
- any deterministic scheduler mode variable
- cutpoint condition, usually before env injection

2. Mailbox/worklist state:

- relevant actor `inbox_count` / mailbox count
- relevant egress/worklist count
- if the cutpoint mailbox is nonempty, selected mailbox cell fields needed by dependency analysis
- for the preferred pre-env cutpoint, usually just empty-mailbox predicates

3. Env-generated packet shape:

- host/env fields that construct the pump packet
- header validity bits required by parser/control
- opcode/type/key fields that determine the update path

4. Control/data dependency predicates:

- table hit/action predicates only when dependence analysis says they affect the update, target index, or mailbox delivery
- branch guard variables on the backward slice from the target write
- hash/partition/cap/index variables on the data-dependence slice
- forwarding/drop predicates that determine whether the next actor in `sche` receives the packet

5. Target index:

- concrete target index value
- source variables used to compute that index when they are not already fixed by env/mailbox projection

Avoid pinning by default:

- target register value itself, except through symbolic `wa_R0` in closure
- unrelated packet payload fields
- debug snapshot variables
- raw solver-introduced temporaries
- scheduler step counters unless needed for deterministic phase replay
- table/action facts not on the control/data slice

## 9. Blocker Generation

When `Closure Check` returns `UNSAFE`, generate a blocker for the next `Entry Check`.

Blocker construction:

1. Build a conjunction of the actor schedule and projection snapshot:

```boogie
wa_actor_0 == ACTOR_ENV &&
wa_actor_1 == ACTOR_s1 &&
wa_actor_2 == ACTOR_s2 &&
wa_target_index == 0bv32 &&
wa_step_delta == 1bvW &&
proj_0 == proj_0_snapshot &&
proj_1 == proj_1_snapshot
```

2. Insert the negation into the next entry query:

```boogie
assume !(...core schedule signature...);
```

or equivalently:

```boogie
if (core_schedule_signature) {
  assume false;
}
```

Preferred implementation:

Use a helper that emits a named boolean expression:

```boogie
procedure {:inline 1} __wa_blocker_000(sig: bool) {
  assume !sig;
}
```

Then add:

```boogie
call __wa_blocker_000(actor_schedule_and_projection_signature);
```

Blocker safety:

- Overblocking can miss an acceleration opportunity, but it must not produce a false certified `UNSAFE`.
- Underblocking may rediscover the same bad schedule and waste iterations. The manifest should detect duplicate `schedule_id` and fail fast with a diagnostic if a blocker is ineffective.

Duplicate protection:

If `Entry Check` returns an actor schedule/projection pair whose `schedule_id` is already blocked, record:

```text
error: ineffective schedule blocker
```

and stop that candidate instead of looping indefinitely.

## 10. CLI And Compatibility Plan

Add an explicit mode flag:

```text
--wraparound-cegar-mode {legacy_closure_assumes,schedule_replay}
```

Default migration plan:

1. Initially default `procurator wraparound` and `procurator verify --wraparound auto` to `legacy_closure_assumes`.
2. Run unit + end-to-end benchmarks with `schedule_replay`.
3. Once the four known wraparound benchmarks certify, switch integrated `verify --wraparound auto` to `schedule_replay`.
4. Keep legacy mode for one release cycle as a debugging fallback.

Stage naming:

- Internally use paper names: `entry_check`, `near_wrap_check`, `closure_check`.
- Keep output filenames compatible where practical:
  - `*.entry_check.bpl`
  - `*.confirm.unrollN.bpl` may remain as an alias for `near_wrap_check`
  - `*.closure_check.bpl`

Manifest should include:

```json
{
  "cegar_mode": "schedule_replay",
  "candidate": "...",
  "attempts": [
    {
      "attempt": 0,
      "schedule": {
        "schedule_id": "...",
        "step_delta": 1,
        "actors": ["env", "s1", "s2"],
        "projection": [...]
      },
      "blockers_in": [],
      "entry": {...},
      "near_wrap": {...},
      "closure": {...},
      "certified": true
    }
  ],
  "blockers": [...]
}
```

## 11. Code Change Plan

### 11.1 New schedule extraction module

Add:

```text
dslc/workflows/wraparound_schedule.py
```

Responsibilities:

- parse `wa_*` ghost variables from GraphML
- normalize RHS values using existing witness utilities
- build `ActorSchedule`
- compute schedule ID
- build Boogie actor-order replay assumptions
- build projection snapshot assumptions
- build schedule blockers
- detect duplicate schedules

Tests:

- `dslc/tests/test_wraparound_schedule_extract.py`
- `dslc/tests/test_wraparound_schedule_blockers.py`

### 11.2 Transform support for schedule replay

Extend or split:

```text
dslc/transform/wraparound_instrument.py
dslc/transform/wraparound_stages.py
```

New inputs:

- `schedule: Optional[ActorSchedule]`
- `blockers: Sequence[ScheduleBlocker]`
- `strict_replay: bool`

Needed helpers:

- emit entry actor-order ghosts
- emit projection snapshot ghosts
- inject blockers into entry
- inject actor-order replay constraints into near-wrap
- inject actor-order replay constraints into closure
- inject projection cutpoint assumptions/assertions into near-wrap and closure
- emit `NoWrap_d` assumptions for positive and negative steps

Tests:

- entry instrumentation contains actor-order ghosts, projection ghosts, and blocker calls
- near-wrap uses actor-order replay plus projection constraints for first wrap step
- closure havocs target value and does not pin target value from witness
- negative-step near-wrap emits correct no-wrap assumption

### 11.3 Workflow loop refactor

In `dslc/workflows/wraparound_cegis.py`:

- keep old `_run_cegis_loop` behavior as legacy mode or wrap it
- add `_run_schedule_replay_cegar_loop`
- use a small `StageRunner` interface as today
- keep incremental manifest writes after every stage

New unit tests:

- `ENTRY -> NEAR_WRAP -> CLOSURE SAFE` returns certified manifest.
- `CLOSURE UNSAFE` creates blocker and reruns `ENTRY`.
- Duplicate schedule after blocker stops with diagnostic.
- `NEAR_WRAP SAFE` does not run `CLOSURE`.
- `NEAR_WRAP UNKNOWN` does not refine.
- `CLOSURE UNKNOWN` does not refine.
- `ENTRY SAFE/UNKNOWN` does not run near-wrap.

### 11.4 Candidate inference updates

`dslc/analysis/wraparound_candidates.py` should expose enough metadata for actor-schedule extraction and projection construction:

- bitwidth of target register
- concrete target index candidates
- P4 action/table names from P4B `wraparound_updates`, if available
- mapping from target register to likely node prefix
- dependency-selected projection predicates, including mailbox/worklist state and env packet shape

If this data is unavailable, schedule mode should fail gracefully with:

```text
candidate missing schedule metadata; falling back to legacy/direct verification
```

### 11.5 Manifest and validation utilities

Extend validation utilities so a certified wraparound manifest can be checked by script:

```text
./bin/procurator validate-wraparound --manifest <manifest.json>
```

Minimum validation:

- manifest schema valid
- `entry` is `UNSAFE`
- `near_wrap` is `UNSAFE`
- `closure` is `SAFE`
- all stages reference the same `schedule_id`
- all referenced BPL/log/witness files exist
- base BPL hash matches schedule hash metadata
- `schedule.conditions == []`

This can be a later patch, but the manifest schema should be designed now.

## 12. Regression Plan

### 12.1 Unit tests after implementation

Run:

```bash
.venv/bin/python -m unittest -v \
  dslc.tests.test_wraparound_schedule_extract \
  dslc.tests.test_wraparound_schedule_blockers \
  dslc.tests.test_wraparound_cegis_order \
  dslc.tests.test_wraparound_cegis_closure_diff_refine \
  dslc.tests.test_wraparound_transform \
  dslc.tests.test_wraparound_workflow_smoke
```

Also keep the existing baseline:

```bash
.venv/bin/python -m unittest -v \
  dslc.tests.test_boogie_backend_smoke \
  dslc.tests.test_boogie_slicing_seeds \
  dslc.tests.test_p4b_translator_slicing_selftest \
  dslc.tests.test_wraparound_workflow_smoke
```

### 12.2 Translator/slicing regression

If P4B metadata or translator instrumentation changes:

```bash
cd P4B-Translator/build-host && make -j16 p4c-translator
```

```bash
P4B-Translator/build-host/p4c-translator \
  -I P4B-Translator/p4include \
  --goto \
  --bmv2cmds Procurator/argo/code/dataset/Netchain/commands_1.txt \
  --slicing-vars=sequence_reg[0] \
  --slicing-selftest=netchain_seq \
  Procurator/argo/code/dataset/Netchain/netchain_16.p4
```

### 12.3 End-to-end wraparound certification cases

Run one at a time with WSL-safe resource limits:

```bash
./bin/procurator verify \
  --spec Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop \
  --boogie-harness sequential \
  --no-two-stage \
  --wraparound auto \
  --wraparound-cegar-mode schedule_replay \
  --wraparound-max-targets 1 \
  --wraparound-confirm-unroll 3 \
  --wraparound-max-confirm-unroll 0 \
  --wraparound-closure-timeout-cap 0 \
  --ultimate-timeout-seconds 1800
```

Then repeat for:

- `Procurator/argo/code/spec/bench/distcache_p2c_wraparound_bug.prop`
- `Procurator/argo/code/spec/bench/distcache_p2c_spineload_wraparound_bug.prop`
- `Procurator/argo/code/spec/bench/fisslock_notification_cnt_wraparound_bug.prop`

Acceptance:

- manifest has `cegar_mode=schedule_replay`
- `entry=UNSAFE`
- `near_wrap/confirm=UNSAFE`
- `closure=SAFE`
- final result is certified wraparound `UNSAFE`
- GraphML witness exists for the near-wrap/confirm suffix

### 12.4 Non-wraparound bug regression

At minimum, after functional code changes, rerun representative non-wrap cases:

```bash
./bin/procurator verify \
  --spec Procurator/argo/code/spec/bench/atp_bug.prop \
  --boogie-harness sequential \
  --no-two-stage \
  --wraparound off \
  --ultimate-timeout-seconds 900
```

```bash
./bin/procurator verify \
  --spec Procurator/argo/code/spec/bench/gecko_bug3_timer_init.prop \
  --boogie-harness sequential \
  --no-two-stage \
  --wraparound off \
  --use-spec-max-steps \
  --no-reg-debug \
  --ultimate-timeout-seconds 900
```

Acceptance:

- still `UNSAFE`
- witness file exists
- no wraparound stage artifacts are required

### 12.5 AGENTS.md experiment record requirement

After running any single-spec experiment, append a record to `AGENTS.md` with:

- spec
- time/date
- progress/result
- whether an implementation bug was encountered
- whether it was fixed
- whether it was added as a smoke/regression test

For pure unit-test-only changes, no single-spec experiment record is needed unless an end-to-end spec was run.

## 13. TNA And V1MODEL Actor-interaction Bug Mining Plan

This is not part of the first CEGAR refactor patch, but the new schedule abstraction should support it.

### 13.1 Corpus discovery

Start from local corpora:

- `P4B-Translator/testdata/tna_p4_16_programs/**`
- `P4B-Translator/testdata/p4_16_samples/**`
- `Procurator/argo/code/dataset/**`

Later, add external open-source programs only with source/license recorded.

### 13.2 Feature classification

Build a script that tags programs by actor-interaction features:

- recirculate/resubmit
- clone/mirror
- multicast
- digest/notification
- register read/write
- counter/meter
- action selector/profile
- metadata-driven forwarding
- TNA-specific intrinsic metadata
- V1MODEL `standard_metadata` egress/clone/recirc paths

Output:

```text
.tmp/procurator/corpus_features/<run_id>.json
```

### 13.3 Bug templates

Generate or hand-author `.prop` specs for these interaction bug patterns:

1. Recirculation reorder:
   two logical packets produce inconsistent downstream order.

2. Clone/drop duplication:
   original and clone both update state when only one should.

3. Mirror/notification stale state:
   notification packet observes state before/after wrong update boundary.

4. Multicast consistency:
   different receivers observe divergent sequence/register values.

5. Register index reuse:
   stale register cell reused after wrap/reset or hash collision.

6. TNA intrinsic metadata mismatch:
   ingress/egress intrinsic fields disagree about port/instance/queue.

7. Counter wraparound:
   schedule-replay CEGAR accelerates deep counter bugs.

### 13.4 End-to-end mining workflow

For each candidate program:

1. Compile P4 with P4B in metadata-only mode when possible.
2. Generate a minimal actor topology and default env skeleton.
3. Run `procurator compile` and `procurator smoke`.
4. Run bounded `verify --wraparound off` for shallow interaction bugs.
5. Run `verify --wraparound auto --wraparound-cegar-mode schedule_replay` for counter-like candidates.
6. Record all `UNSAFE` candidates with:
   - witness path
   - target P4 code path
   - actor interaction category
   - whether the bug is likely real or modeling-induced

## 14. Migration Risks And Mitigations

Risk: actor schedule/projection extraction from GraphML is brittle.

Mitigation:

- emit explicit actor-order and projection `wa_*` ghost variables and parse those first
- keep sourcecode parsing only as fallback
- unit-test with minimized GraphML fragments

Risk: schedule blocker over-constrains and misses valid schedules.

Mitigation:

- blocker mode only affects acceleration, never ordinary direct verification
- detect duplicates
- keep blockers to actor order plus the projection snapshot, not arbitrary event traces
- preserve legacy mode during rollout

Risk: closure proof becomes too hard when projection includes too much packet state.

Mitigation:

- split projection predicates into mandatory and optional
- start with scheduler/cutpoint, mailbox counts, env pump shape, target index, and dependence-selected control/data predicates
- add mailbox packet cell payload only if the cutpoint is after env injection or closure counterexample shows it matters

Risk: near-wrap check becomes too constrained and misses a suffix bug.

Mitigation:

- default strict replay only for the first wrap step
- release subsequent suffix to full harness semantics
- provide `--wraparound-strict-replay` for paper experiments

Risk: current benchmark scripts expect `confirm` naming.

Mitigation:

- keep filename aliases and manifest compatibility fields
- add `near_wrap` as a new field but still populate `confirm`

Risk: dirty worktree and existing user edits.

Mitigation:

- keep changes scoped
- do not revert existing edits
- use additive modules/tests first

## 15. Open Questions Before Implementation

These are the only points that need confirmation before changing code:

1. Should `schedule_replay` become the default immediately after its unit tests pass, or should it remain opt-in until all four known wraparound end-to-end cases certify?

Recommended: opt-in first, default after the four known cases certify.

2. If `Near-wrap Check` is `SAFE` for one synthesized schedule, should we block that schedule and search for another schedule, or follow the paper text and fall back/direct-check the slot?

Recommended: paper-compatible fallback by default; optional exploratory mode can keep searching.

3. Should strict replay constrain only the first wrap step or the entire near-wrap suffix?

Recommended: constrain the first wrap step by default, then release the suffix to full semantics for stronger bug finding; add a strict flag for paper-style experiments.

## 16. Definition Of Done

The CEGAR refactor is done when:

1. `schedule_replay` mode exists behind a CLI flag.
2. A schedule extracted from `Entry Check` has a stable `schedule_id`.
3. `Near-wrap Check` and `Closure Check` both reference the same `schedule_id`.
4. `Closure Check UNSAFE` produces a blocker and reruns `Entry Check`.
5. `Closure Check UNKNOWN` does not refine.
6. Certified manifests require `ENTRY UNSAFE + NEAR_WRAP UNSAFE + CLOSURE SAFE + schedule.conditions == []`.
7. Unit tests cover loop ordering, blockers, duplicate detection, and stage gating.
8. Existing Python smoke tests pass.
9. At least `netchain_wraparound_bug.prop` certifies end to end in `schedule_replay` mode.
10. After broader validation, all four known wraparound benchmarks certify in `schedule_replay` mode.
