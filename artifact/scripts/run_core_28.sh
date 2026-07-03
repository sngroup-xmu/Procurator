#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [[ -z "${PYTHON:-}" ]]; then
  if [[ -x "${ROOT}/.venv-wsl/bin/python3" ]]; then
    PYTHON="${ROOT}/.venv-wsl/bin/python3"
  else
    PYTHON="python3"
  fi
fi

OUT_DIR="${OUT_DIR:-${ROOT}/.tmp/procurator/artifact}"
ACTUAL="${ACTUAL:-${OUT_DIR}/core_28.actual.json}"
mkdir -p "${OUT_DIR}"

export PYTHONPATH="${ROOT}/src:${ROOT}/src/p4b/python${PYTHONPATH:+:${PYTHONPATH}}"

"${PYTHON}" "${ROOT}/src/dslc/bench/run_e2e_ablations.py" \
  --results-json "${ACTUAL}" \
  --timeout "${TIMEOUT_SECONDS:-3600}" \
  --ultimate-xmx-gb "${ULTIMATE_XMX_GB:-4}" \
  "$@"

"${PYTHON}" "${ROOT}/artifact/scripts/check_expected.py" \
  --expected "${ROOT}/artifact/expected/core_28.expected.json" \
  --actual "${ACTUAL}"

echo "core_28 actual: ${ACTUAL}"
