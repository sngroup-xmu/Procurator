# Example And Result Data

The repository contains runnable examples and archived result data. The curated
28-benchmark dataset is stored under `artifact/results/core_28/`.

Check the archived result in place:

```bash
artifact/scripts/check_expected.py \
  --expected artifact/expected/core_28.expected.json \
  --actual artifact/results/core_28/core_28.casewise.actual.json
```

Fresh reproductions use the same expected-profile gates. Scripts can generate
tables from archived evidence or from new `.tmp/procurator/` outputs. The
checkers fail closed on inconclusive solver results.
