#!/usr/bin/env bash
# Container entrypoint for the Procurator image.
set -euo pipefail
cd /procurator

export PYTHONPATH="/procurator/src:/procurator/src/p4b/python${PYTHONPATH:+:${PYTHONPATH}}"
PY=/procurator/.venv-wsl/bin/python3
ULTIMATE_BIN="${ULTIMATE:-/opt/ultimate/UGemCutter-linux/Ultimate}"
P4B_BIN=/procurator/src/p4b/source/build-host/backends/verify/p4c-translator

usage() {
  cat <<'USAGE'
Procurator image. Everything runs inside the container; mount a host
directory so results persist:

  docker run --rm -v "$PWD/ae-out:/procurator/.tmp/procurator" procurator <command> [args]

Verify or compile a spec (normal use):

  verify --spec /work/atp_bug.prop     # run the verifier on one spec
  compile --spec /work/atp_bug.prop    # only emit the Boogie file

  The bundled benchmark specs live under /procurator/benchmarks/specs/.
  Mount your own spec files under /work, e.g.
    -v "$PWD/my.prop:/work/my.prop"
  --ultimate/--p4b-bin/--toolchain/--settings are pre-configured; pass your
  own to override.

Artifact evaluation (reproduce the archived results):

  ae           the whole evaluation as one command: smoke, 28-bug suite in
               both modes, wraparound audit, compile/runtime table (~2-4 h)
  smoke        ~1 min sanity check of the CLI + compile + solver pipeline
  core28       just the 28-benchmark suite (slicing + noslicing)
  wraparound   the four wraparound tasks with certificate validation
  tables       compile/runtime table + CSV summary (needs core28 results)

help         this message

Results (JSON verdicts, logs, witnesses) land in the mounted ae-out/ dir.
See artifact/README.md, section "How to read the results", for the verdict
fields and the pass/fail policy.
USAGE
}

cmd="${1:-help}"
if [[ $# -gt 0 ]]; then shift; fi

case "$cmd" in
  ae)         exec artifact/scripts/run_all.sh "$@" ;;
  smoke)      exec artifact/scripts/run_smoke.sh "$@" ;;
  core28)     exec artifact/scripts/run_core_28_casewise.sh "$@" ;;
  wraparound) exec artifact/scripts/run_wraparound_4.sh "$@" ;;
  tables)
    artifact/scripts/run_compile_runtime.sh
    exec "$PY" artifact/scripts/make_tables.py
    ;;
  verify|compile)
    has_opt() { local n="$1"; shift; local a; for a in "$@"; do [[ "$a" == "$n" || "$a" == "$n="* ]] && return 0; done; return 1; }
    extra=()
    has_opt --ultimate "$@"  || extra+=(--ultimate "$ULTIMATE_BIN")
    has_opt --p4b-bin "$@"   || extra+=(--p4b-bin "$P4B_BIN")
    if [[ "$cmd" == "verify" ]]; then
      has_opt --toolchain "$@" || extra+=(--toolchain src/dslc/toolchain/ultimate/ReachSafety.xml)
      has_opt --settings "$@"  || extra+=(--settings src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL.epf)
    fi
    exec "$PY" src/bin/procurator "$cmd" "$@" "${extra[@]}"
    ;;
  help|*)     usage ;;
esac
