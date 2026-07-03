# Third-Party Software

The public release keeps first-party code under `src/` and third-party source
or provenance under `third_party/`.

- P4B/p4c fork: full pinned fork in `src/p4b/source/`; it is part of the
  first-party source layout for this release.
- Ultimate/GemCutter: pinned source/provenance under `third_party/ultimate/`.
  The artifact setup script downloads the Linux GemCutter binary bundle into
  ignored `.tmp/` local state for runs.
- Z3: solver dependency provided by the artifact environment or release setup.

Before archival, verify all third-party and benchmark dataset licenses listed
in `third_party/MANIFEST.json` and `benchmarks/MANIFEST.json`.
