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

P4B_BIN="${P4B_BIN:-${ROOT}/src/p4b/source/build-host/backends/verify/p4c-translator}"
ULTIMATE="${ULTIMATE:-}"
OUT_DIR="${OUT_DIR:-${ROOT}/.tmp/procurator/artifact}"
ACTUAL="${ACTUAL:-${OUT_DIR}/smoke.actual.json}"
COMPILE_OUT="${OUT_DIR}/smoke/boogie_smoke.bpl"
COMPILE_WORK="${OUT_DIR}/smoke/work"
SOLVER_LOG="${OUT_DIR}/smoke/gemcutter.log"

mkdir -p "${OUT_DIR}/smoke"

export PYTHONPATH="${ROOT}/src:${ROOT}/src/p4b/python${PYTHONPATH:+:${PYTHONPATH}}"

cli_help=error
compile_status=error
solver_status=SKIPPED
solver_classification=inconclusive
solver_log=""

if "${PYTHON}" "${ROOT}/src/bin/procurator" --help >/dev/null; then
  cli_help=ok
fi

if [[ ! -x "${P4B_BIN}" ]]; then
  echo "missing executable P4B translator: ${P4B_BIN}" >&2
else
  rm -rf "${COMPILE_WORK}"
  if "${PYTHON}" "${ROOT}/src/bin/procurator" compile \
      --spec "${ROOT}/benchmarks/specs/smoke/boogie_smoke.prop" \
      --backend boogie \
      --out "${COMPILE_OUT}" \
      --work-dir "${COMPILE_WORK}" \
      --p4b-bin "${P4B_BIN}" >/dev/null; then
    compile_status=ok
  fi
fi

if [[ -z "${ULTIMATE}" ]]; then
  for candidate in \
    "${ROOT}/.tmp/procurator/toolchains/gemcutter/UGemCutter-linux/Ultimate" \
    "${ROOT}"/.tmp/orphan-worktree-*/UGemCutter-linux/Ultimate \
    "${ROOT}/third_party/ultimate/UGemCutter-linux/Ultimate" \
    "${ROOT}/Ultimate"; do
    if [[ -f "${candidate}" ]]; then
      ULTIMATE="${candidate}"
      break
    fi
  done
fi

if [[ -n "${ULTIMATE}" && -x "${ULTIMATE}" && "${compile_status}" == "ok" ]]; then
  set +e
  solver_output="$("${PYTHON}" "${ROOT}/src/bin/procurator" verify \
    --spec "${ROOT}/benchmarks/specs/smoke/boogie_smoke.prop" \
    --out "${OUT_DIR}/smoke/boogie_smoke.verify.bpl" \
    --work-dir "${OUT_DIR}/smoke/verify-work" \
    --p4b-bin "${P4B_BIN}" \
    --ultimate "${ULTIMATE}" \
    --ultimate-timeout-seconds "${ULTIMATE_TIMEOUT_SECONDS:-30}" \
    --ultimate-xmx-gb "${ULTIMATE_XMX_GB:-2}" \
    --toolchain "${ROOT}/src/dslc/toolchain/ultimate/ReachSafety.xml" \
    --settings "${ROOT}/src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-internal.epf" \
    --log "${SOLVER_LOG}" 2>&1)"
  solver_rc=$?
  set -e
  solver_log="${SOLVER_LOG}"
  if printf '%s\n' "${solver_output}" | grep -q 'RESULT:.*incorrect\|RESULT:.*UNSAFE'; then
    solver_status=UNSAFE
    solver_classification=solver_result
  elif printf '%s\n' "${solver_output}" | grep -q 'RESULT:.*correct\|RESULT:.*SAFE'; then
    solver_status=SAFE
    solver_classification=solver_result
  elif printf '%s\n' "${solver_output}" | grep -qi 'timeout'; then
    solver_status=TIMEOUT
    solver_classification=inconclusive
  elif [[ ${solver_rc} -eq 0 ]]; then
    solver_status=UNKNOWN
    solver_classification=inconclusive
  else
    solver_status=ERROR
    solver_classification=inconclusive
  fi
fi

"${PYTHON}" - "${ACTUAL}" <<PY
import json
import sys
from pathlib import Path

actual = {
    "profile": "smoke",
    "cli_help": "${cli_help}",
    "compile": "${compile_status}",
    "solver": {
        "status": "${solver_status}",
        "classification": "${solver_classification}",
        "log": "${solver_log}",
    },
}
path = Path(sys.argv[1])
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(actual, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

"${PYTHON}" "${ROOT}/artifact/scripts/check_expected.py" \
  --expected "${ROOT}/artifact/expected/smoke.expected.json" \
  --actual "${ACTUAL}"

echo "smoke actual: ${ACTUAL}"
