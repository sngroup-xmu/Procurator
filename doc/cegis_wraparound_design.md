# CEGIS For Wraparound Bugs (Design Notes)

This note documents a *CEGIS/CEGAR-style* workflow for wraparound bug finding in
`procurator wraparound`.

Goal: given a functional property that can be violated due to counter wraparound
(e.g., DistCache P2C wrong-choice after `leafload` wraps), automatically/robustly:

1) obtain a *pump/suffix script sketch* (usually provided in the DSL spec, as a
   small two-phase Host/Env program) that reaches the +1 update point of the
   target register,
2) compute a **sound acceleration gate** via `closure_check`,
3) fast-forward to the wrap boundary and confirm the *functional property*
   violation quickly.

This is designed to prevent pseudo counterexamples caused by unreachable wrap
states, while keeping bug-finding practical on 32-bit counters.

---

## Background: Why We Need Synthesis

Many data-plane programs maintain 16/32-bit counters in registers. Direct BMC
from 0 to `MAX-1` is infeasible, and naive "set register to MAX-1" is unsound
because the state might be unreachable from the modeled initial state.

Procurator's wraparound pipeline addresses this by splitting the task:

1) `closure_check`: prove a *closed* per-round summary of the counter update
   (e.g., `x := x + 1`) under a projection of the system state.
2) `confirm`: fast-forward the counter to `MAX` and search the short suffix that
   flips to 0 and violates a functional property.

However, for many real bugs, we also need to automatically find *how to trigger*
the `+1` update in the first place (which packet shape / which control-plane
entry / which phase).

---

## CEGIS View

We treat "find a stable pump loop" as a synthesis problem:

- **Unknowns (to synthesize)**
  - An *input script* (finite-state environment) that injects packets of certain
    shapes (e.g., opcodes) in a periodic pattern.
  - Optionally, a *projection* (a set of variables required to remain stable)
    used by the wraparound acceleration.

- **Constraints (to satisfy)**
  1) The script must make the target register cell update by `+delta` once per
     scheduler round (for all `seq0 != MAX`): proven by `closure_check`.
  2) The script must preserve a projection of system state relevant to the
     later functional property (no drift that would invalidate fast-forward).

- **Verifier**
  - Ultimate (GemCutter/Automizer) on the generated Boogie model.

---

## v0: Sketch-Based CEGIS + Small CEGAR Refinements (What We Actually Implement)

We treat the *input synthesis* part as **CEGIS with a user-provided sketch**:

- The spec provides a tiny finite-state input program (typically `dsl_pump_mode`)
  that selects between:
  - a pump packet shape (triggers `+1`), and
  - a suffix packet shape (triggers the functional property check).

The tool then **checks and refines** the remaining pieces needed for a sound and
fast wraparound proof:

1) **Infer fixed register index (when needed).**
   Some programs update `reg[meta.idx]`, but `meta.idx` may be uninitialized at
   the wraparound cutpoint. We infer the effective constant index from BMv2
   entries/topology (e.g., DistCache partitions: leaf eport=2, spine eport=3)
   and override `index_expr` to a concrete `bv32` constant.

2) **Infer hash-domain caps from BMv2 entries.**
   DistCache uses hash tables with finite ranges (e.g., `0x0..0xf`). We patch
   the base Boogie to add `assume(hashval <= 0xf)` so the intended table actions
   stay enabled and the proof does not drown in unrelated nondeterminism.

3) **CEGAR-ish projection refinement (currently heuristic).**
   Closure proofs fail if we project unstable per-packet meta (hash outputs,
   derived indices). We therefore drop:
   `*.hashval_*`, `*.leafswitchidx`, `*.spineswitchidx` from the default closure
   projection, keeping only stable scheduler/queue counters.

This is enough to make `closure_check` provable and keep `confirm` within a few
minutes on the real DistCache P2C wraparound bug.

---

## Soundness Contract

In this workflow we treat:

- `confirm` UNSAFE as *sound evidence of a real bug from initial state* **only if**
  the corresponding `closure_check` for that candidate script is SAFE.

Rationale:
  - `closure_check` ensures we can reach the pre-wrap boundary (`MAX-1`) by
    repeating the closed update summary without changing the projected context.
  - Without `closure_check`, confirm UNSAFE could be a pseudo bug caused by
    forcing `x := MAX` in an unreachable state.

---

## Example: DistCache P2C Overflow Wrong-Choice

Spec: `Procurator/argo/code/spec/bench/distcache_p2c_wraparound_bug.prop`

Two-packet script:
  1) `optype = 0x2009` -> `update_leaf_load` (forces `leafload := leafload + 1`)
  2) `optype = 0x30`   -> `poweroftwochoice` (compares `leafload/spineload`)

Confirm stage fast-forwards `leafload` to `MAX`:
  - After packet (1), `leafload` becomes 0 (overflow).
  - Packet (2) sees `leafload==0` and may choose leaf incorrectly.

Functional assertion:
  - If processing the P2C query and observing `leafload==0` while `spineload==1`,
    then `meta.is_spine` must be 1 (choose spine), otherwise the load-balancing
    policy is violated.

---

## Future Work (v1+)

1) Full CEGAR refinement of projection:
   - Start with a conservative projection (scheduler + queue counters + property
     dependencies), then use counterexamples to *weaken* only non-essential
     variables until `closure_check` becomes SAFE.

2) Richer script synthesis (beyond a sketch):
   - Synthesize additional header fields beyond a single opcode key when needed
     (e.g., include hash keys, validity bits, parser reachability).

3) Multi-node pump synthesis:
   - Extend the approach to distributed programs where the pump action depends
     on upstream deliveries (requires topology-aware env synthesis).
