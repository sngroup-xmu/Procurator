#!/usr/bin/env bash
# Build the self-contained Procurator image (see README.md in this directory).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
docker build -t procurator "$@" "${ROOT}"
