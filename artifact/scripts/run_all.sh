#!/usr/bin/env bash
# One-shot artifact evaluation for the SIGCOMM'26 Procurator artifact.
#
# Runs, in order:
#   1. toolchain checks (installs pinned Ultimate/GemCutter if missing)
#   2. smoke: CLI + P4B-to-Boogie compile + solver pipeline
#   3. core_28: the curated 28-bug suite, slicing and noslicing modes
#      (paper Section 8.1 bug-finding + Section 8.3 slicing ablation)
#   4. wraparound_4: the four wraparound tasks with certificate validation
#      (paper Section 8.3 wraparound acceleration)
#   5. compile/runtime table from the core_28 records (paper Table 3 data)
#   6. CSV summary
#
# Pinned hyperparameters (identical to the archived 2026-07-04 dataset):
#   solver settings  src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL.epf
#   solver timeout   900 s per task (1800 s for two tasks; TIMEOUT_SECONDS overrides)
#   solver heap      4 GB per run (ULTIMATE_XMX_GB overrides)
#
# Expected total wall time: about 2-4 hours on a 16-core Linux/WSL host.
# All transient output lands under .tmp/procurator/artifact/.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT}"

if [[ -z "${PYTHON:-}" ]]; then
  if [[ -x "${ROOT}/.venv-wsl/bin/python3" ]]; then
    PYTHON="${ROOT}/.venv-wsl/bin/python3"
  else
    PYTHON="python3"
  fi
fi

DRY_RUN=0
for arg in "$@"; do
  if [[ "${arg}" == "--dry-run" ]]; then
    DRY_RUN=1
  fi
done

step() { printf '\n===== [%s] %s =====\n' "$(date +%H:%M:%S)" "$*"; }

step "toolchain checks"
ULTIMATE_BIN="${ULTIMATE:-${ROOT}/.tmp/procurator/toolchains/gemcutter/UGemCutter-linux/Ultimate}"
if [[ ! -x "${ULTIMATE_BIN}" ]]; then
  echo "Ultimate/GemCutter not found; installing the pinned release"
  artifact/scripts/setup_gemcutter.sh
fi
P4B_BIN="${P4B_BIN:-${ROOT}/src/p4b/source/build-host/backends/verify/p4c-translator}"
if [[ ! -x "${P4B_BIN}" ]]; then
  echo "missing P4B translator: ${P4B_BIN}" >&2
  echo "build it first (docs/tutorial.md):" >&2
  echo "  mkdir -p src/p4b/source/build-host && cd src/p4b/source/build-host" >&2
  echo "  cmake -DP4C_USE_GOLD=OFF -DENABLE_GTESTS=OFF .." >&2
  echo "  cmake --build . --target p4c-translator -j\"\$(nproc)\"" >&2
  exit 1
fi
echo "Ultimate: ${ULTIMATE_BIN}"
echo "P4B:      ${P4B_BIN}"
echo "Python:   ${PYTHON}"

step "smoke: CLI + compile + solver pipeline"
artifact/scripts/run_smoke.sh

step "core_28: 28 curated bugs x {slicing, noslicing} (about 2-4 h)"
artifact/scripts/run_core_28_casewise.sh "$@"

step "wraparound_4: certified wraparound evidence"
artifact/scripts/run_wraparound_4.sh "$@"

if [[ "${DRY_RUN}" -eq 1 ]]; then
  echo "run_all dry-run: stopping before compile/runtime table"
  exit 0
fi

step "compile/runtime table (from the core_28 records)"
artifact/scripts/run_compile_runtime.sh

step "CSV summary"
"${PYTHON}" artifact/scripts/make_tables.py

step "done"
echo "all expected-profile checks passed; outputs under .tmp/procurator/artifact/"
