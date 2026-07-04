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
CASES_DIR="${CASES_DIR:-${OUT_DIR}/cases}"
ACTUAL="${ACTUAL:-${OUT_DIR}/core_28.casewise.actual.json}"
mkdir -p "${OUT_DIR}" "${CASES_DIR}"

export PYTHONPATH="${ROOT}/src:${ROOT}/src/p4b/python${PYTHONPATH:+:${PYTHONPATH}}"

DRY_RUN=0
for arg in "$@"; do
  if [[ "${arg}" == "--dry-run" ]]; then
    DRY_RUN=1
  fi
done

mapfile -t BENCHES < <(
  "${PYTHON}" "${ROOT}/src/dslc/bench/run_e2e_ablations.py" --list |
    sed -n 's|.*benchmarks/specs/bench/\([^/()]*\)\.prop.*|\1|p'
)

if [[ "${#BENCHES[@]}" -eq 0 ]]; then
  echo "no benchmarks discovered from run_e2e_ablations.py --list" >&2
  exit 1
fi

for bench in "${BENCHES[@]}"; do
  for mode in slicing noslicing; do
    ACTUAL="${CASES_DIR}/${bench}.${mode}.actual.json" \
      PYTHON="${PYTHON}" \
      "${ROOT}/artifact/scripts/run_benchmark_case.sh" \
      --bench "${bench}" \
      --only "${mode}" \
      --timeout "${TIMEOUT_SECONDS:-3600}" \
      --ultimate-xmx-gb "${ULTIMATE_XMX_GB:-4}" \
      "$@"
  done
done

if [[ "${DRY_RUN}" -eq 1 ]]; then
  echo "core_28 casewise dry-run: skipped merge/check after printing per-case commands"
  exit 0
fi

MERGE_ARGS=()
for bench in "${BENCHES[@]}"; do
  MERGE_ARGS+=(--bench "${bench}")
done

"${PYTHON}" "${ROOT}/artifact/scripts/merge_case_results.py" \
  --cases-dir "${CASES_DIR}" \
  --out "${ACTUAL}" \
  "${MERGE_ARGS[@]}"

"${PYTHON}" "${ROOT}/artifact/scripts/check_expected.py" \
  --expected "${ROOT}/artifact/expected/core_28.expected.json" \
  --actual "${ACTUAL}"

echo "core_28 casewise actual: ${ACTUAL}"
