#!/usr/bin/env bash
set -euo pipefail
docker build -t procurator:artifact "$(dirname "$0")"
