# P4B p4c Fork

`src/p4b/source/` contains the full pinned P4B/p4c fork used by Procurator. It
is intentionally kept as a complete source tree rather than a small patch layer
because the verify backend and supporting changes are broad.

Default build:

```bash
mkdir -p src/p4b/source/build-host
cd src/p4b/source/build-host
cmake -DP4C_USE_GOLD=OFF -DENABLE_GTESTS=OFF ..
cmake --build . --target p4c-translator -j"$(nproc)"
```

The preferred binary location is
`src/p4b/source/build-host/backends/verify/p4c-translator`; some local builds
may also place a compatibility wrapper at
`src/p4b/source/build-host/p4c-translator`.
