# AGENTS.md

This repository uses a short agent entrypoint.  The former long running log was
compressed into `HARDRULES.md`; follow that file before doing implementation,
verification, documentation, or Git work.

## Required Reading

1. Read `HARDRULES.md` first.
2. Treat `HARDRULES.md` as mandatory workflow policy, not background notes.
3. Do not append long experiment logs to this file.

## Core Rules

1. Never treat `TIMEOUT`, `UNKNOWN`, OOM, toolchain `ERROR`, missing witness, or
   unverified `SAFE` as bug absence.
2. If generated BPL/harness semantics are wrong, fix P4B/DSLC modeling before
   spending solver time.
3. If BPL/harness semantics are right, allow enough solver time and record the
   exact stage result. Short timeouts are inconclusive.
4. Keep P4-local semantics in P4B and distributed harness/proof orchestration in
   DSLC.
5. Stage and commit by feature. Do not mix datasets, PDFs, IDE files, workspace
   noise, or unrelated generated artifacts into implementation commits.
6. Run the regression set that matches the touched feature before claiming it is
   done.
7. Use WSL for P4B-dependent or solver-heavy runs. Windows Python is acceptable
   only for pure Python tests that do not touch Linux P4B binaries.
8. Use `git diff --check` on staged files before committing.

## Experiment Records

Per-spec experiment records should go to a dedicated evidence file or report, not
back into this entrypoint.  Each record must include:

- spec or test target
- exact time
- command/configuration
- result and run id
- artifact and witness paths, when any
- pitfall/root cause, when any
- fix and regression/smoke test

Keep records factual.  Do not over-certify beyond the evidence that was actually
validated.

## Current Camera-Ready Focus

The active engineering goal is to keep Procurator/P4B camera-ready evidence
auditable:

- PSA/eBPF/uBPF/PNA/TNA coverage must distinguish discovery from semantic audit.
- Input inference and slicing must expose enough evidence to justify keep/havoc
  decisions.
- Cross-pass and pipeline dependencies for recirculate/resubmit/clone/mirror must
  be tested with P4B selftests.
- Wraparound `ENTRY_CHECK` / `NEAR_WRAP` / `CLOSURE_CHECK` evidence must fail
  closed.  Focused diagnostics are not certification.
- Known theoretical bugs must rerun to auditable `UNSAFE` evidence or remain
  explicitly inconclusive, never silently marked absent.

## Git Notes

Routine Git under WSL `/mnt/...` can hang or be slow.  Prefer Windows Git or a
non-`/mnt` WSL checkout for Git operations.  If SSH push fails with public-key
errors, use the HTTPS remote as a one-shot fallback or fix credentials before
claiming push is complete.
