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
ACTUAL="${ACTUAL:-${OUT_DIR}/wraparound_4.actual.json}"
mkdir -p "${OUT_DIR}"

export PYTHONPATH="${ROOT}/src:${ROOT}/src/p4b/python${PYTHONPATH:+:${PYTHONPATH}}"

"${PYTHON}" "${ROOT}/src/dslc/bench/run_e2e_ablations.py" \
  --results-json "${ACTUAL}" \
  --timeout "${TIMEOUT_SECONDS:-3600}" \
  --ultimate-xmx-gb "${ULTIMATE_XMX_GB:-4}" \
  --bench netchain_wraparound_bug \
  --bench distcache_p2c_spineload_wraparound_bug \
  --bench distcache_p2c_wraparound_bug \
  --bench fisslock_notification_cnt_wraparound_bug \
  "$@"

"${PYTHON}" "${ROOT}/artifact/scripts/check_expected.py" \
  --expected "${ROOT}/artifact/expected/wraparound_4.expected.json" \
  --actual "${ACTUAL}"

"${PYTHON}" "${ROOT}/artifact/scripts/validate_wraparound_manifests.py" \
  --results-json "${ACTUAL}"

echo "wraparound_4 actual: ${ACTUAL}"
