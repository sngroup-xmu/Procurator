# Cross-Pass Input and Wraparound Gap Closure Design

Date: 2026-05-13

## 2026-05-13 Execution Addendum

After review, this camera-ready slice is intentionally scoped as audit/naming/reproducibility alignment over the already implemented algorithms. The current codebase already contains the core slicer, input-pruning, and wraparound certification machinery. Therefore:

- We do not replace the slicer with a new algorithm in this slice.
- We treat passing P4B selftests for recirculate and clone/mirror payload retention as the required cross-pass evidence for the present camera-ready checkpoint.
- We expose Input Inference evidence in backend profiles instead of changing the pruning policy.
- We expose paper-stage names in wraparound manifests without weakening the existing certification/fallback rules.
- Any future helper-level refactor of cross-pass event domains should preserve the selftests added by this slice and be reviewed as a maintainability refactor, not as a new semantic feature.

## Goal

Close the implementation gaps between the paper design and the current Procurator implementation without weakening existing semantics. The work turns the current IR pruner, symbolic input inference, and schedule-replay wraparound acceleration into a camera-ready, auditable implementation:

- Cross-pass and pipeline data dependencies are explicit, tested, and aligned with recirculate, resubmit, clone, and mirror semantics.
- Input Inference exposes `Keep[v]` and `Havoc[v]` evidence instead of only applying pruning internally.
- Three-stage wraparound acceleration reports only certified bugs when the paper stage triple is satisfied, and otherwise falls back without treating unknown or timeout as absence.

## Current Baseline

This design starts from the current implementation, not from a blank slate.

- P4B already builds a semantic slicing graph for P4 IR. It collects statement use/def sets, table/action summaries, register-action summaries, parser dependencies, header-stack effects, and a pipeline CFG derived from common `main` architecture instances.
- P4B already has a cross-pass mechanism. When recirculation or clone/mirror behavior is detected, the slicer adds a pass-exit to pass-entry edge and builds additional reaching-definition edges for packet-carried and persistent state.
- DSLC already implements intent-driven seed selection. Assertions and DSL statements contribute slicing seeds; assumptions and env statements constrain the model and keep declarations, but do not become slice criteria.
- DSLC already implements symbolic input pruning. It collects packet and metadata variables from P4B Boogie output, filters unused inputs after slicing, force-keeps required DSL/env variables, and rejects missing declarations instead of ghost-declaring them.
- DSLC already implements schedule-replay wraparound stages and strict manifest certification gates.

The remaining work is therefore not to add a conservative fallback pruner. It is to make the paper algorithms explicit, complete their event-specific edges, and preserve evidence.

## Design A: Cross-Pass Event Payload Dependencies

### Problem

The current slicer has a cross-pass loop-back edge, but the event payload semantics are implicit. For camera-ready correctness, Algorithm 2 `CrossPassAugment` must be represented as an explicit event-domain rule:

- Which event creates the cross-pass edge.
- Which stage produces the payload.
- Which stage consumes the payload.
- Which variables may be carried across that edge.

This matters for recirculate and mirror programs where a field written before the event is read in a later pass. Dropping that write causes a false negative or a spurious model.

### Event Domains

The implementation will define event payload domains with these rules:

- `recirculate` / `resubmit`: self-delivery from egress to a later ingress pass. The carried domain is the active packet payload that the harness preserves for internal enqueue. This includes `hdr.*` and architecture metadata that is explicitly part of the recirculated packet model, but not arbitrary global state.
- `clone_i2i`: self-delivery from ingress to a later ingress pass. The carried domain is the ingress clone payload.
- `clone_i2e`: local egress worklist delivery from ingress to egress. The carried domain is the ingress-to-egress clone snapshot.
- `clone_e2e`: local egress worklist delivery from egress to a later egress step. The carried domain is the egress-to-egress clone snapshot.
- Cross-node forwarding: only on-wire headers are copied across actors. In this repository, that is `hdr.*`. Node-local `meta.*`, `standard_metadata.*`, and target intrinsic metadata do not propagate across topology links.
- Stateful objects such as registers are persistent actor state. They are dependencies across passes but are not packet payload.

### Implementation Shape

P4B will get an explicit helper-level model for cross-pass event domains in the slicer. The helper may live in the existing slicer implementation files, but the code must make the domain rules visible through named functions rather than burying them inside a broad `crossOk` predicate.

The helper will feed the current reaching-definition augmentation:

1. Build ordinary same-pass DDG from the pipeline CFG.
2. Detect whether eventful externs or synthetic `p4b_*` flags are present.
3. Add event-specific pass edges.
4. On those event edges, admit only variables in the event payload domain or persistent state.
5. Run backward slicing over the augmented DDG.

### Acceptance Tests

P4B selftests must cover the event edges:

- `recirc_payload_flow`: egress writes an on-packet field and triggers recirculation; next-pass logic or the slicing seed observes that field. Slicing must retain the egress write and the recirculation trigger.
- `i2i_mirror_payload_flow`: ingress writes an on-packet field and triggers I2I clone; next ingress observes that field. Slicing must retain the write and clone call.
- `i2e_e2e_payload_flow`: ingress or egress writes a field before an I2E/E2E clone; the egress worklist path observes it. Slicing must retain the payload write and clone flag.
- `cross_node_hdr_only`: a downstream `hdr.*` seed propagates to an upstream node, while a downstream `meta.*` seed does not.

Existing selftests such as `recirc_meta_flow`, `netchain_seq`, `netchain_pop_front`, `frr_pkt_par_write`, and DistCache register-alias tests must keep passing.

## Design B: Input Inference Evidence

### Problem

The implementation already computes the practical equivalent of the paper's `Havoc[v]`, but the result is only visible indirectly in generated Boogie. For camera-ready evaluation and debugging, each compile should have a compact evidence record showing why a packet variable is kept, havoced, pruned, or skipped.

### Evidence Contract

For each node, the backend compile profile will record:

- `slicing_keep`: P4B slicing variables and keep variables.
- `required_packet_vars`: packet variables referenced by DSL assumptions, env statements, assertions, or host logic.
- `raw_input_vars`: packet/meta variables discovered in the raw or sliced P4B Boogie output.
- `havoc_input_vars`: final variables that the harness may havoc.
- `pruned_input_vars`: raw inputs removed by input inference.
- `force_keep_input_vars`: required or seed packet vars kept even if the sliced Boogie body no longer references them directly.
- `skipped_control_outputs`: forwarding or target output metadata intentionally excluded from external havoc, such as `egress_spec`, `egress_port`, and `ucast_egress_port`.

### Semantics

- Assume-only fields do not become slicing seeds.
- Assume-only or env fields that are still referenced by generated harness code remain declared and usable.
- Deterministic top-level env writes may avoid redundant havoc.
- Self-referential env writes keep havoc.
- Forwarding control outputs are not external inputs.
- Missing P4 packet declarations remain hard errors. The backend must not synthesize ghost packet variables to make an invalid slice typecheck.

### Acceptance Tests

Add DSLC unit tests that compile small specs and inspect the compile profile or generated BPL:

- An assume-only field appears in `required_packet_vars` and not in `slicing_keep`.
- A property field appears in `slicing_keep` and final `havoc_input_vars` when needed.
- A forwarding output field appears in `skipped_control_outputs` and is not havoced.
- A self-referential env assignment still emits havoc.
- No test relies on ghost declarations for missing fields.

## Design C: Two-Stage Harness Alignment

### Problem

The DSLC harness already has two-stage ingress/egress scheduling for eventful nodes and snapshots scalar packet/meta variables to avoid mixing packets. The slicer and the harness must use the same conceptual field domains so that pruning does not remove a value the harness later needs to carry.

### Contract

- The slicer event payload domain must match the harness mailbox/snapshot domain at the level of semantics.
- The harness remains responsible for distributed actor scheduling, mailboxes, egress worklists, and topology forwarding.
- P4B remains responsible for P4-local payload dependencies, table/action dependencies, parser dependencies, and register state dependencies.

### Acceptance Tests

Existing two-stage tests remain part of the gate:

- Eventful nodes get two-stage wrappers; non-eventful nodes do not.
- Two-stage egress snapshots extend modifies sets.
- Queue capacity 2 uses two-slot inbox and two-slot egress queues.

New tests from Design A must ensure P4B slicing retains payload writes needed by those later harness events.

## Design D: Three-Stage Wraparound Certification

### Problem

The code has schedule-replay stages, but the manifest and result semantics must make the paper mapping unambiguous. This is also where NEAR_WRAP false negatives must be eliminated: a safe, timeout, or unknown acceleration stage cannot be reported as the bug being absent.

### Paper Stage Mapping

- Stage 1: `ENTRY_CHECK`
- Stage 2: `NEAR_WRAP`
- Stage 3: `CLOSURE_CHECK`

Legacy or internal names such as `CONFIRM` may remain as compatibility fields, but the manifest and user-facing certification should prefer the paper stage names.

### Certification Rule

A schedule-replay result is certified only when all of the following hold:

- `ENTRY_CHECK` is reachable and has evidence.
- `NEAR_WRAP` is reachable and has evidence.
- `CLOSURE_CHECK` is `SAFE`.
- Projection is complete for the target and schedule.
- The same target, schedule identity, and projected shape connect the three stages.
- There are no closure assumptions that weaken certification.

All other acceleration outcomes are non-decisive.

### Fallback Rule

In integrated `verify --wraparound auto`:

- Unsupported acceleration, incomplete projection, `NEAR_WRAP=SAFE`, `NEAR_WRAP=UNKNOWN`, `NEAR_WRAP=TIMEOUT`, `CLOSURE_CHECK=UNKNOWN`, and `CLOSURE_CHECK=TIMEOUT` must trigger ordinary direct checking when possible.
- If ordinary direct checking is not run or returns unknown/timeout/error, the final result is unknown or uncertified, not safe.
- A non-certified acceleration result may be recorded as diagnostic evidence, but it must never erase a known theoretical bug.

### Acceptance Tests

Add or strengthen wraparound tests:

- `NEAR_WRAP=SAFE` produces a non-certified outcome and requests direct fallback.
- closure timeout produces an uncertified manifest.
- certification requires the exact stage triple and projection completeness.
- manifest exposes the paper stage names.

## Design E: Architecture Coverage Evidence

This design does not reimplement PSA/eBPF/uBPF/PNA/TNA support. It requires the existing coverage tooling to distinguish evidence levels:

- discovery-only
- full translation
- slicing-enabled translation
- semantic audit
- distributed harness compile/smoke

The coverage report must not blend discovery-only counts with semantic validation.

## Rollout Order

1. Add failing tests for cross-pass event payload dependencies.
2. Implement explicit P4B cross-pass event-domain logic.
3. Add Input Inference evidence to backend profiles and tests.
4. Add wraparound stage-name and fallback certification tests, then update manifest/reporting code.
5. Run focused regression.
6. Record completed specs and pitfalls in `AGENTS.md`.

## Non-Goals

- Do not invent a new verifier backend.
- Do not weaken slicing by globally retaining all metadata.
- Do not treat acceleration as the only verification path.
- Do not claim semantic-audit coverage from discovery-only scans.
- Do not auto-declare missing packet fields.

## Success Criteria

- P4B selftests demonstrate recirculate and mirror payload dependencies.
- DSLC tests demonstrate `Keep[v]` / `Havoc[v]` split and no ghost fields.
- Wraparound tests demonstrate strict certification and sound fallback.
- Existing smoke tests for P4B slicing, DSLC Boogie backend, two-stage harness, and wraparound workflow pass.
- `AGENTS.md` records any single-spec reruns with spec, time, progress, implementation pitfalls, fixes, and smoke tests.
