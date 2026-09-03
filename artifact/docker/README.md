# Procurator Docker image

A self-contained Docker image for Procurator. The image bundles the compiled
P4B translator (P4 -> Boogie), the pinned Ultimate/GemCutter solver (v0.3.1,
sha256-checked at build time), the Python CLI, and all 28 benchmark specs.
Nothing is downloaded at run time.

## Build

From the repository root (20-40 min; ~3 GB image):

```bash
docker build -t procurator .
```

(`artifact/docker/build.sh` does exactly this.)

## Run

`artifact/docker/run.sh` mounts `./ae-out/` for results and forwards its
arguments; you can also call `docker run` directly.

Verify a single spec (normal use):

```bash
# a bundled benchmark spec:
artifact/docker/run.sh verify --spec benchmarks/specs/bench/atp_bug.prop

# your own spec (mount it under /work):
docker run --rm -v "$PWD/my.prop:/work/my.prop" \
  -v "$PWD/ae-out:/procurator/.tmp/procurator" \
  procurator verify --spec /work/my.prop
```

`verify` comes pre-configured with the solver, the P4B translator, the
ReachSafety toolchain, and the pinned `-ALL` settings profile; pass your own
`--ultimate/--p4b-bin/--toolchain/--settings` to override.

Reproduce the archived evaluation (one command, ~2-4 h):

```bash
artifact/docker/run.sh ae
```

Finer-grained steps: `smoke`, `core28`, `wraparound`, `tables`. See
`artifact/README.md` for what each step produces and how to read the results
(everything lands in `./ae-out/`).

## Resource notes

- The solver runs with a 4 GB Java heap per task (override with
  `ULTIMATE_XMX_GB`); tasks run sequentially. On Docker Desktop
  (Windows/macOS) give the VM at least 8 GB of memory.
- Default solver timeout is 900 s per task (override with `TIMEOUT_SECONDS`).
- The build uses all host cores by default; limit with
  `docker build --build-arg JOBS=8 -t procurator .` on machines with little
  RAM.
