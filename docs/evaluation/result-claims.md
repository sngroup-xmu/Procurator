# Result interpretation

Every result statement must distinguish compiled, smoked, solver `UNSAFE`,
witness rerun, certified closure, timeout, unknown, and skipped outcomes.
Under-approximate evidence may prove `UNSAFE`; it must not prove absence.

The repository includes one archived result dataset for the curated bug suite:

- Actual JSON: `artifact/results/core_28/core_28.casewise.actual.json`
- Result manifest: `artifact/results/core_28/MANIFEST.json`
- Human-readable reproduction table:
  `artifact/evidence/core_28_casewise_reproduction_20260704.md`
- Classification audit:
  `artifact/evidence/actor_wraparound_audit_28_cases.md`

This archived run records all 28 curated benchmarks in both `slicing` and
`noslicing` mode. The expected-profile checker accepts only conclusive statuses;
`TIMEOUT`, `UNKNOWN`, OOM, toolchain `ERROR`, missing witnesses, and unaudited
`SAFE` are not bug absence.
