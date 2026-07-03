# Artifact

The artifact entrypoint is `artifact/README.md`. Source code lives under
`src/`, third-party dependencies under `third_party/`, and benchmark inputs
under `benchmarks/`.

Smoke command shape:

```bash
./src/bin/procurator verify \
  --spec benchmarks/specs/smoke/boogie_smoke.prop \
  --p4b-bin src/p4b/source/build-host/backends/verify/p4c-translator \
  --ultimate third_party/ultimate/UGemCutter-linux/Ultimate
```
