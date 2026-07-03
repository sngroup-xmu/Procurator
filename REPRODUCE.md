# Reproducing Results

Use `artifact/scripts/` for reviewer-facing runs. Scripts should write outputs
under `.tmp/procurator/` or an explicit output directory and then compare them
against `artifact/expected/`.

Result interpretation must fail closed: timeout, unknown, OOM, toolchain error,
missing witness, and unverified safe results are inconclusive.

Minimal local smoke:

```bash
artifact/scripts/setup_gemcutter.sh
artifact/scripts/run_smoke.sh
```

Case-by-case benchmark reproduction:

```bash
artifact/scripts/run_benchmark_case.sh --bench netchain_wraparound_bug --only slicing
artifact/scripts/run_benchmark_case.sh --bench netchain_wraparound_bug --only noslicing
```

Use this form while tuning or validating implementation changes. It writes one
actual JSON under `.tmp/procurator/artifact/cases/` and checks only that case,
without weakening fail-closed semantics. Re-run already-passing cases after a
fix before expanding the regression set.

Full profiles:

```bash
artifact/scripts/run_core_28.sh
artifact/scripts/run_wraparound_4.sh
artifact/scripts/run_compile_runtime.sh
```

The full scripts may take hours. They write actual JSON files under
`.tmp/procurator/artifact/` and then run `artifact/scripts/check_expected.py`.
If a run times out or lacks witness/manifest evidence, the checker reports it as
inconclusive or failed rather than treating it as a reproduced result.
