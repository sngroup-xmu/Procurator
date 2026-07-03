# p4c Build Notes

The artifact builds `p4c-translator` from `src/p4b/source`. The source tree is
the full pinned P4B/p4c fork and is managed as first-party source in this
release layout because the local verify backend changes are broad.

Recommended CMake options:

```bash
-DP4C_USE_GOLD=OFF -DENABLE_GTESTS=OFF
```

Procurator's default resolver first looks for
`build-host/backends/verify/p4c-translator` inside this fork, then falls back to
`build-host/p4c-translator`, then to the repo-local Docker wrapper.
