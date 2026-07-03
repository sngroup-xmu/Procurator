# Artifact

The artifact entrypoint is `artifact/README.md`. Source code lives under
`src/`, third-party dependencies under `third_party/`, and benchmark inputs
under `benchmarks/`.

Smoke command shape:

```bash
artifact/scripts/setup_gemcutter.sh
artifact/scripts/run_smoke.sh
```

Large benchmark cases should be tuned and regression-checked one at a time:

```bash
artifact/scripts/run_benchmark_case.sh --bench netchain_wraparound_bug --only slicing
```

The GemCutter setup script downloads the pinned Ultimate GemCutter Linux release
into ignored `.tmp/` local state. Do not commit the downloaded binary bundle.
