#!/usr/bin/env bash
set -euo pipefail

# End-to-end smoke:
#   DSL (.prop) -> concurrent Boogie (.bpl) -> Ultimate/GemCutter run -> grep RESULT.
#
# Usage (example):
#   /mnt/e/p4-verify/Procurator/argo/code/spec/prop_compile/run_boogie_gemcutter_smoke.sh \
#     --p4b-bin /mnt/e/p4-verify/P4B-Translator/build-host/backends/verify/p4c-translator \
#     --ultimate /tmp/ultimate/UGemCutter-linux/Ultimate

SPEC="/mnt/e/p4-verify/Procurator/argo/code/spec/test/boogie_smoke.prop"
OUT_DIR="/tmp/procurator_smoke"
P4B_BIN=""
ULTIMATE_BIN="/mnt/e/p4-verify/UGemCutter-linux/Ultimate"

TOOLCHAIN="/mnt/e/p4-verify/ultimate/trunk/examples/concurrent/bpl/regression/ReachSafety.xml"
SETTINGS="/mnt/e/p4-verify/ultimate/trunk/examples/concurrent/bpl/regression/ReachSafety-32bit-GemCutter.epf"

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
  echo "[ERR] missing --p4b-bin" >&2
  exit 2
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
  echo "      Hint: pass --ultimate /mnt/e/p4-verify/UGemCutter-linux/Ultimate" >&2
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
/mnt/e/p4-verify/.venv/bin/python -m dslc.compiler \
  --backend boogie \
  --spec "$SPEC" \
  --out "$OUT_BPL" \
  --p4b-bin "$P4B_BIN" \
  --work-dir "$WORK_DIR"

echo "[RUN] structural + Ultimate smoke"
# Ultimate settings typically reference solver as plain `z3`, so ensure Ultimate's directory is on PATH.
ULT_DIR="$(cd "$(dirname "$ULTIMATE_BIN")" && pwd)"
export PATH="$ULT_DIR:$PATH"
/mnt/e/p4-verify/.venv/bin/python /mnt/e/p4-verify/Procurator/argo/code/spec/prop_compile/gemcutter_smoke.py \
  --bpl "$OUT_BPL" \
  --ultimate-run "$ULTIMATE_BIN" \
  --toolchain "$TOOLCHAIN" \
  --settings "$SETTINGS" \
  > "$LOG" 2>&1 || true

echo "[LOG] $LOG"
grep -nE 'RESULT|AllSpecificationsHoldResult|proved your program|incorrect|TypeErrorResult|SyntaxErrorResult|Exception' "$LOG" | tail -n 80 || true
