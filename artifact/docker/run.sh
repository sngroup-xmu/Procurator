#!/usr/bin/env bash
set -euo pipefail
docker run --rm -it -v "$PWD:/procurator" procurator-ae:camera-ready "$@"
