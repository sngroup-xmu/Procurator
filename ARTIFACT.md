# Artifact

The artifact entrypoint is `artifact/README.md`. Source code lives under
`src/`, third-party dependencies under `third_party/`, and benchmark inputs
under `benchmarks/`.

Smoke command shape:

```bash
artifact/scripts/setup_gemcutter.sh
artifact/scripts/run_smoke.sh
```

The GemCutter setup script downloads the pinned Ultimate GemCutter Linux release
into ignored `.tmp/` local state. Do not commit the downloaded binary bundle.
