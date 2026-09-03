#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="${VERSION:-v0.3.1}"
SHA256="${SHA256:-6c9f663bd00758185baaf2878a44891c53d7a0d5ac2193113d95752eb0453b16}"
URL="${URL:-https://github.com/ultimate-pa/ultimate/releases/download/${VERSION}/UltimateGemCutter-linux.zip}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-${ROOT}/.tmp/downloads}"
INSTALL_ROOT="${INSTALL_ROOT:-${ROOT}/.tmp/procurator/toolchains/gemcutter}"
ZIP="${DOWNLOAD_DIR}/UltimateGemCutter-linux-${VERSION}.zip"

mkdir -p "${DOWNLOAD_DIR}" "${INSTALL_ROOT}"

if [[ ! -s "${ZIP}" ]]; then
  for attempt in 1 2 3 4 5; do
    # Stall watchdog: abort if below 10 KB/s for 30 s, then resume with -C -.
    curl -L --fail --show-error --progress-bar \
      --speed-limit 10240 --speed-time 30 \
      -C - -o "${ZIP}" "${URL}" && break
    echo "download attempt ${attempt} failed; retrying" >&2
    sleep 3
  done
fi

actual_sha="$(sha256sum "${ZIP}" | awk '{print $1}')"
if [[ "${actual_sha}" != "${SHA256}" ]]; then
  echo "sha256 mismatch for ${ZIP}" >&2
  echo "expected: ${SHA256}" >&2
  echo "actual:   ${actual_sha}" >&2
  exit 1
fi

rm -rf "${INSTALL_ROOT}/UGemCutter-linux"
unzip -q "${ZIP}" -d "${INSTALL_ROOT}"
chmod +x "${INSTALL_ROOT}/UGemCutter-linux/Ultimate"

"${INSTALL_ROOT}/UGemCutter-linux/Ultimate" --help >/dev/null 2>&1

cat <<EOF
GemCutter installed:
  ${INSTALL_ROOT}/UGemCutter-linux/Ultimate

Use:
  export ULTIMATE='${INSTALL_ROOT}/UGemCutter-linux/Ultimate'
EOF
