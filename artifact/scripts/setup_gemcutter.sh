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
  # Try a direct download first; if it crawls below 200 KB/s for 20 s,
  # abort and resume through public GitHub mirror prefixes. The sha256
  # check below pins the content regardless of the source.
  MIRROR_PREFIXES=("" "https://gh-proxy.com/" "https://ghfast.top/" "https://ghproxy.net/")
  downloaded=0
  for prefix in "${MIRROR_PREFIXES[@]}"; do
    for attempt in 1 2; do
      if curl -L --fail --show-error --progress-bar \
          --speed-limit 204800 --speed-time 20 \
          -C - -o "${ZIP}" "${prefix}${URL}"; then
        downloaded=1
        break
      fi
      echo "download via '${prefix:-direct}' failed or too slow; trying next source" >&2
      sleep 2
    done
    [[ "${downloaded}" -eq 1 ]] && break
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
