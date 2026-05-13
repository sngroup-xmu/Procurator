# HARDRULES

This file is the compressed rulebook distilled from `AGENTS.md`.
It is intentionally short and should stay under 300 lines.

## Source Size

- Source log: `AGENTS.md`
- Measured at: 2026-05-13 22:53 Asia/Shanghai
- Size: 768,250 bytes
- Lines: 6,449
- Purpose: `AGENTS.md` remains the append-only audit log; this file is the durable operating summary.

## Non-Negotiable Semantics

1. Never interpret `TIMEOUT`, `UNKNOWN`, toolchain `ERROR`, OOM, missing witness, or unverified `SAFE` as bug absence.
2. A `SAFE` result is meaningful only with the stage semantics that produced it and the certification checks required by that stage.
3. For wraparound, certification requires the intended proof chain evidence, not just a successful focused or diagnostic query.
4. If a model or harness is semantically wrong, fix translation/modeling first; do not spend solver time on a wrong BPL.
5. If generated BPL/harness shape is correct, solver time may need to be long. Short timeouts are not negative evidence.
6. Every result statement must distinguish: compiled, smoked, solver UNSAFE, witness rerun, certified closure, timeout, unknown, and skipped.
7. Under-approximate evidence may prove `UNSAFE`; it must never prove absence.
8. Fail closed. If a condition cannot be proved, fallback to the conservative path.

## P4B / DSLC Ownership

9. P4-local semantics belong in P4B: parser/control/package handling, extern lowering, hash semantics, register writes, table semantics, pipeline-local dependencies, architecture metadata.
10. DSLC owns distributed semantics: topology, actor scheduling, queues, environment modeling, pass-atomic harness, projection closure, wraparound orchestration, certificates, and fallback policy.
11. Avoid re-parsing P4-local meaning from emitted Boogie when a typed P4B metadata contract or translator-side implementation can own it.
12. DSLC may retain compatibility backfills for legacy BPL imports, but P4B-generated nodes must emit complete native metadata/mirrors.
13. Do not duplicate the same semantic rule in both P4B and DSLC unless one side is explicitly legacy compatibility.
14. When moving logic across the boundary, keep compatibility tests for old BPL and fail-fast tests for incomplete P4B output.

## Input Inference And Slicing

15. Input inference evidence must explain `Keep[v]`, `Havoc[v]`, pruned inputs, forced-kept inputs, and skipped control outputs.
16. `assume`/environment constraints restrict inputs; they are not automatically property seeds.
17. Slicing seeds come from assertions and DSL property dependencies, plus conservative packet-field propagation over topology.
18. Only on-wire packet fields should propagate upstream across links by default; node-local metadata must not be treated as wire state.
19. Host/env packet variables required by assumptions must remain declared even when they are not P4 slicing seeds.
20. Missing declarations should be repaired based on structured variable discovery, not ghost variables guessed from text alone.
21. Cross-pass events include recirculate, resubmit, clone, and mirror. Do not let a name like `hasRecirculation` narrow the semantics accidentally.
22. For recirculate/mirror/clone programs, payload dependencies across pass or pipeline boundaries must be regression-tested with P4B selftests.
23. Slicing may reduce state space, but if sliced and unsliced disagree on `UNSAFE`, first suspect an over-pruned semantic dependency.

## Architecture Coverage

24. Coverage claims for PSA/eBPF/uBPF/PNA/TNA must name the evidence mode.
25. `--list-only` is discovery evidence, not semantic validation.
26. `--semantic-audit` evidence must record target, sample root, result counts, skips, failures, and generated report path.
27. `SKIP` is not `FAIL`; both must be reported separately.
28. Target helper summaries are valid audit evidence only when explicitly recorded as summaries, not silently treated as fully precise lowering.
29. Paths with spaces and quoted include dependencies must be handled because external sample roots are often messy.
30. Do not generalize from one backend or architecture sample to all PSA/eBPF/uBPF/PNA/TNA support.

## Hashes, Externs, And Helpers

31. Use precise lowering for BMv2 CRC16/CRC32 where available.
32. For uBPF/PNA/TNA helper hashes, record whether the implementation is precise lowering or a target-helper summary.
33. Hash/index definitions are semantic dependencies for register access and slicing; they need tests, not just successful compilation.
34. A helper summary can support auditability but must not be oversold as bit-exact semantics.
35. Any helper used by wraparound candidate inference must be conservative enough not to invent a pump.

## Register Mirrors

36. Register write mirrors are part of P4-local semantics and should be emitted natively by P4B.
37. Required mirrors include last index, last value, old value, slot-0 old/value, wrote-any, wrote-index0, next write site, and last write site when the feature needs them.
38. DSLC legacy BPL backfill may repair missing mirrors for imported BPL only.
39. P4B-generated nodes missing register markers or complete mirror modifies must fail fast.
40. Old/new/write-site fail-fast assertions must be constrained to the focused write/site; broad old fail-fast checks are not certification.
41. Register mirror debug variables are optional performance aids; disabling debug must not leave stale `modifies` references.
42. Mirror tests must cover idempotence: no duplicate declarations, no duplicate assignments, no duplicate modifies entries.

## Wraparound Stages

43. Use paper-facing stage names consistently: `ENTRY_CHECK`, `NEAR_WRAP`, `CLOSURE_CHECK`.
44. Focused near-wrap is diagnostic/acceleration evidence; it is not certified confirm/closure evidence by itself.
45. Manifest validation must reject focused-near artifacts if they are used as certified confirm evidence.
46. Closure certification requires stable projection evidence and explicit closure equalities for projected variables/predicates.
47. Projection predicates need explicit sources. Missing predicate sources make the certificate unauditable.
48. Scalar projection without closure equality is not certified.
49. Closure-prefix and closure-suffix failed attempts must be recorded as notes, not erased.
50. A failed closure attempt does not weaken a later successful certificate, but it must remain auditable.
51. Confirm witness and closure proof serve different purposes; do not merge their meanings.
52. CEGIS refinement should not bias or erase the existence witness.

## Wraparound Candidate Rules

53. Export monotonic/wraparound pump candidates only for steady affine updates.
54. Reset-prone or multiple-write counters must not be exported as steady pumps.
55. Candidate `step_delta`, `step_op`, target register, index, and projection variables must be explicit in manifests.
56. Fixed slot evidence may use scalar mirrors to reduce array burden, but fallback must remain available.
57. Dynamic slot defaults require dominating initialization evidence.
58. Hash-derived slots must be treated as dependencies; constant hash slots may be folded only with proof/test evidence.

## Focused Direct / Bounded Replay

59. Bounded DSL replay may accept `UNSAFE` early only when the final bad guard is known to be violated.
60. Unknown tail control flow, unknown external calls, or unknown target register state must fall back unless the final guard is already decided.
61. A replay marker must include auditable kind/path evidence and be accepted by CLI, ablation classification, and witness summary together.
62. CLI output for under-approximate `UNSAFE` must print `[RESULT] RESULT: UNSAFE`; otherwise runners may classify it as `ERROR`.
63. Relative marker paths must be resolved against the correct working directory, not guessed from marker location.
64. Synthetic replay logs are evidence only for the under-approximation they state.

## Known Bug Revalidation

65. For every known theoretical bug rerun, record spec, time, parameters, result, run id, artifact directory, witness path, and sanity result.
66. Before running a solver, inspect generated BPL/harness for the relevant semantic path and final assertion.
67. Witness rerun `UNSAFE` is stronger evidence than a single solver result.
68. A missing entry in the results JSON is not a negative result.
69. OOM under a low-memory profile should lead to a pinned stronger profile or model reduction, not bug absence.
70. If historical runs disagree with current runs, compare generated BPLs before drawing performance conclusions.
71. Do not compare timing across runs polluted by unrelated heavy IO or background searches.
72. Keep old failing run ids/logs when they explain a pitfall.

## Solver And Runtime Practice

73. Run solver-heavy and P4B-dependent tests in WSL.
74. Do not run Linux P4B binaries directly from PowerShell.
75. Windows-side Python may be fine for pure Python tests, but not for tests that need Linux P4B build paths.
76. Do not run multiple Ultimate/GemCutter jobs concurrently unless explicitly planned.
77. Prefer default resource limits: CPU/IO niceness and bounded Java heap.
78. Use high-memory small-blocks profiles for known large Gecko/DDOSD/NetLock-style cases when recorded.
79. A profile change must be documented as configuration evidence, not hidden as a code fix.

## Git And Workspace Practice

80. The worktree may be dirty. Never revert user or unrelated generated changes without explicit request.
81. Stage only the files owned by the current feature.
82. Keep doc/evidence commits separate from implementation commits.
83. Commit by feature: audit reporting, translator semantics, register mirrors, wraparound replay, AGENTS/HARDRULES docs.
84. Do not mix external datasets, PDFs, IDE workspace files, or unrelated sample edits into feature commits.
85. Routine Git under WSL `/mnt/...` can hang or be very slow; prefer Windows git or a non-`/mnt` WSL path for Git operations.
86. If a Git command hangs and leaves `.git/index.lock`, first identify/stop the stuck process, then remove a stale lock only after confirming no live Git writer remains.
87. Push may require HTTPS fallback if SSH reports `Permission denied (publickey)`.

## Regression Minimums

88. P4B translator semantic changes require `p4c-translator` rebuild plus targeted P4B tests/selftests.
89. DSLC backend/harness changes require backend smoke tests and any ownership-specific tests.
90. Wraparound transformation changes require focused-direct, closure-transform, schedule, certification, and manifest-validator tests.
91. Coverage tooling changes require scanner/audit unit tests.
92. Counterexample or replay classification changes require validator and ablation-classifier tests.
93. If a test is skipped due to environment, state the environment reason and run the equivalent valid command.
94. `git diff --check` must pass for staged files before commit.

## Documentation Rules

95. `AGENTS.md` is append-only detailed evidence; keep recording single-spec experiments there.
96. `HARDRULES.md` is the compressed operational rulebook; update it when a repeated pitfall becomes durable policy.
97. Every AGENTS entry for a spec should include: spec, time, progress/result, pitfall/root cause, fix, and smoke/regression tests.
98. Do not over-certify. Say exactly what was validated and what remains unproven.
99. Camera-ready claims must map paper terms to implementation evidence and name remaining audit boundaries.
100. Keep this file concise. If it grows toward 300 lines, consolidate instead of appending more history.
