#!/usr/bin/env bash
set -euo pipefail
docker build -t procurator-ae:camera-ready "$(dirname "$0")"
