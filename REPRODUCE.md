# Reproducing Results

Use `artifact/scripts/` for reviewer-facing runs. Scripts should write outputs
under `.tmp/procurator/` or an explicit output directory and then compare them
against `artifact/expected/`.

Result interpretation must fail closed: timeout, unknown, OOM, toolchain error,
missing witness, and unverified safe results are inconclusive.
