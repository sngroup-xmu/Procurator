#!/usr/bin/env bash
# Run the Procurator image. Results persist in ./ae-out/.
# Examples:
#   artifact/docker/run.sh verify --spec /work/atp_bug.prop
#   artifact/docker/run.sh ae
set -euo pipefail
mkdir -p "${PWD}/ae-out"
exec docker run --rm -v "${PWD}/ae-out:/procurator/.tmp/procurator" procurator "$@"
