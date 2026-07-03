# Third-Party License Notes

This file is a release checklist, not a replacement for upstream license files.

Required before public archival:

- Confirm the P4B/p4c fork license files under `src/p4b/source/LICENSES/`.
- Confirm Ultimate/GemCutter redistribution terms for any bundled binary.
- Confirm whether Z3 is provided by the Docker image, a fetch script, or a
  release asset.
- Confirm benchmark dataset licenses listed in `benchmarks/MANIFEST.json`.

The release checks require each core dependency to have a non-empty name, path,
license, and provenance entry in `third_party/MANIFEST.json`.
