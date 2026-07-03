# Installation

Recommended environment: Ubuntu 24.04 or WSL with Java and the packages needed
to build the pinned P4B/p4c fork.

Build the translator:

```bash
mkdir -p src/p4b/source/build-host
cd src/p4b/source/build-host
cmake -DP4C_USE_GOLD=OFF -DENABLE_GTESTS=OFF ..
cmake --build . --target p4c-translator -j"$(nproc)"
```

The preferred translator binary is:

```text
src/p4b/source/build-host/backends/verify/p4c-translator
```

Install Python requirements:

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r src/dslc/requirements.txt
```

Install the local GemCutter runtime used by artifact scripts:

```bash
artifact/scripts/setup_gemcutter.sh
export ULTIMATE="$PWD/.tmp/orphan-worktree-20260703-gemcutter/UGemCutter-linux/Ultimate"
```

The downloaded Ultimate bundle is local environment state under `.tmp/` and is
not committed. The tracked `third_party/ultimate/` directory records the pinned
source/provenance side of the dependency.
