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

BENCH=""
ONLY="${ONLY:-all}"
EXTRA_ARGS=()
DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --bench)
      BENCH="${2:-}"
      shift 2
      ;;
    --only)
      ONLY="${2:-}"
      shift 2
      ;;
    *)
      if [[ "$1" == "--dry-run" ]]; then
        DRY_RUN=1
      fi
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ -z "${BENCH}" ]]; then
  echo "usage: $0 --bench <benchmark-substring> [--only slicing|noslicing|all] [runner args]" >&2
  exit 2
fi

case "${ONLY}" in
  all|slicing|noslicing) ;;
  *)
    echo "invalid --only: ${ONLY}" >&2
    exit 2
    ;;
esac

OUT_DIR="${OUT_DIR:-${ROOT}/.tmp/procurator/artifact/cases}"
mkdir -p "${OUT_DIR}"
SLUG="$(printf '%s.%s' "${BENCH}" "${ONLY}" | tr -cs 'A-Za-z0-9._-' '_')"
ACTUAL="${ACTUAL:-${OUT_DIR}/${SLUG}.actual.json}"

export PYTHONPATH="${ROOT}/src:${ROOT}/src/p4b/python${PYTHONPATH:+:${PYTHONPATH}}"

"${PYTHON}" "${ROOT}/src/dslc/bench/run_e2e_ablations.py" \
  --results-json "${ACTUAL}" \
  --bench "${BENCH}" \
  --only "${ONLY}" \
  "${EXTRA_ARGS[@]}"

if [[ "${DRY_RUN}" -eq 1 ]]; then
  echo "benchmark case dry-run: ${BENCH} (${ONLY})"
  exit 0
fi

"${PYTHON}" "${ROOT}/artifact/scripts/validate_benchmark_case.py" \
  --results-json "${ACTUAL}" \
  --bench "${BENCH}" \
  --only "${ONLY}"

echo "benchmark case actual: ${ACTUAL}"
