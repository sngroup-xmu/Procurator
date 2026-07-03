#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

"${ROOT}/src/bin/procurator" --help >/dev/null

echo "CLI smoke completed. Configure p4c-translator and Ultimate before running verification."
