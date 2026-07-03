#!/usr/bin/env bash
set -euo pipefail

# End-to-end smoke:
#   DSL (.prop) -> concurrent Boogie (.bpl) -> Ultimate/GemCutter run -> grep RESULT.
#
# Usage (example):
#   benchmarks/specs/prop_compile/run_boogie_gemcutter_smoke.sh \
#     --p4b-bin src/p4b/source/build-host/backends/verify/p4c-translator \
#     --ultimate UGemCutter-linux/Ultimate

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
  REPO_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"
fi

SPEC="$REPO_ROOT/benchmarks/specs/smoke/boogie_smoke.prop"
OUT_DIR="/tmp/procurator_smoke"
P4B_BIN=""
ULTIMATE_BIN="$REPO_ROOT/UGemCutter-linux/Ultimate"

# Default to a non-witness toolchain: the witness printer can throw on SAFE results.
TOOLCHAIN="$REPO_ROOT/benchmarks/specs/config/ClosureCheck-ReachSafety.xml"
SETTINGS="$REPO_ROOT/benchmarks/specs/config/ReachSafety-32bit-GemCutter-ALL.epf"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --spec)
      SPEC="$2"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="$2"
      shift 2
      ;;
    --p4b-bin)
      P4B_BIN="$2"
      shift 2
      ;;
    --ultimate)
      ULTIMATE_BIN="$2"
      shift 2
      ;;
    --toolchain)
      TOOLCHAIN="$2"
      shift 2
      ;;
    --settings)
      SETTINGS="$2"
      shift 2
      ;;
    *)
      echo "[ERR] unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$P4B_BIN" ]]; then
  if [[ -x "$REPO_ROOT/src/p4b/source/build-host/backends/verify/p4c-translator" ]]; then
    P4B_BIN="$REPO_ROOT/src/p4b/source/build-host/backends/verify/p4c-translator"
  elif [[ -x "$REPO_ROOT/src/p4b/source/build-host/p4c-translator" ]]; then
    P4B_BIN="$REPO_ROOT/src/p4b/source/build-host/p4c-translator"
  else
    echo "[ERR] missing --p4b-bin (and default $REPO_ROOT/src/p4b/source/build-host/backends/verify/p4c-translator not found)" >&2
    exit 2
  fi
fi
if [[ -n "$ULTIMATE_BIN" && ! -x "$ULTIMATE_BIN" && -f "$ULTIMATE_BIN" ]]; then
  # Some checkouts may not preserve executable bit; attempt best-effort.
  chmod +x "$ULTIMATE_BIN" 2>/dev/null || true
fi
if [[ -z "$ULTIMATE_BIN" ]]; then
  echo "[ERR] missing --ultimate" >&2
  exit 2
fi
if [[ ! -x "$ULTIMATE_BIN" ]]; then
  echo "[ERR] Ultimate not found or not executable: $ULTIMATE_BIN" >&2
  echo "      Hint: pass --ultimate $REPO_ROOT/UGemCutter-linux/Ultimate" >&2
  exit 2
fi

mkdir -p "$OUT_DIR"
OUT_BPL="$OUT_DIR/boogie_smoke.bpl"
WORK_DIR="$OUT_DIR/boogie_smoke.work"
LOG="$OUT_DIR/boogie_smoke_gemcutter.log"

# For determinism: clear previous artifacts (avoid mixing old logs/models).
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

echo "[RUN] compile DSL -> Boogie: $SPEC"
echo "[RUN] verify (compile + Ultimate/GemCutter): $SPEC"
# Ultimate settings typically reference solver as plain `z3`, so ensure Ultimate's directory is on PATH.
ULT_DIR="$(cd "$(dirname "$ULTIMATE_BIN")" && pwd)"
export PATH="$ULT_DIR:$PATH"
"$REPO_ROOT/src/bin/procurator" verify \
  --spec "$SPEC" \
  --out "$OUT_BPL" \
  --work-dir "$WORK_DIR" \
  --p4b-bin "$P4B_BIN" \
  --ultimate "$ULTIMATE_BIN" \
  --toolchain "$TOOLCHAIN" \
  --settings "$SETTINGS" \
  --log "$LOG" \
  > "$LOG" 2>&1 || true

echo "[LOG] $LOG"
grep -nE 'RESULT|AllSpecificationsHoldResult|proved your program|incorrect|TypeErrorResult|SyntaxErrorResult|Exception' "$LOG" | tail -n 80 || true
