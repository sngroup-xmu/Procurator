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
if [[ -z "${RESULTS_JSON:-}" ]]; then
  if [[ -f "${OUT_DIR}/core_28.casewise.actual.json" ]]; then
    RESULTS_JSON="${OUT_DIR}/core_28.casewise.actual.json"
  else
    RESULTS_JSON="${OUT_DIR}/core_28.actual.json"
  fi
fi
ACTUAL="${ACTUAL:-${OUT_DIR}/compile_runtime.actual.json}"
REPORT_MD="${REPORT_MD:-${OUT_DIR}/compile_runtime.md}"
mkdir -p "${OUT_DIR}"

if [[ ! -f "${RESULTS_JSON}" ]]; then
  echo "missing E2E results JSON: ${RESULTS_JSON}" >&2
  echo "run artifact/scripts/run_core_28_casewise.sh first, or set RESULTS_JSON=<path>" >&2
  exit 1
fi

export PYTHONPATH="${ROOT}/src:${ROOT}/src/p4b/python${PYTHONPATH:+:${PYTHONPATH}}"

"${PYTHON}" "${ROOT}/src/dslc/bench/collect_compile_runtime_report.py" \
  --results-json "${RESULTS_JSON}" \
  --out-json "${ACTUAL}" \
  --out-md "${REPORT_MD}" \
  "$@"

"${PYTHON}" "${ROOT}/artifact/scripts/check_expected.py" \
  --expected "${ROOT}/artifact/expected/compile_runtime.expected.json" \
  --actual "${ACTUAL}"

echo "compile_runtime actual: ${ACTUAL}"
echo "compile_runtime report: ${REPORT_MD}"
