# Ultimate Notes

Ultimate/GemCutter requires a compatible Java runtime and solver setup. Public
artifact scripts should use the pinned paths recorded under `third_party/`.

`procurator verify` defaults to `ReachSafety-32bit-GemCutter-internal.epf`,
which is stored under
`src/dslc/toolchain/ultimate/settings/gemcutter/base/`. Pass a different
`--settings` value only when a run needs a witness, no-POR, smallblocks, or
higher-memory profile.
