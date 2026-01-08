#!/usr/bin/env bash
set -euo pipefail

# Run P4B-Translator's `p4c-translator` inside Docker.
#
# This avoids installing heavyweight build/runtime deps (flex/bison/protobuf/boost/libgc)
# into the host WSL environment.
#
# Usage (same as p4c-translator):
#   p4b_docker.sh <P4File> -o <outFile> [--bmv2cmds <file>] [--ua2 --p4ltl <file>] ...
#
# Environment:
#   P4B_DOCKER_IMAGE  Docker image name (default: p4b-translator:local)

IMAGE="${P4B_DOCKER_IMAGE:-p4b-translator:local}"

if ! command -v docker >/dev/null 2>&1; then
  echo "[ERR] docker not found in PATH" >&2
  exit 127
fi

# Mount /mnt for workspace paths (WSL) and /tmp for intermediate outputs.
exec docker run --rm \
  -v /mnt:/mnt \
  -v /tmp:/tmp \
  "${IMAGE}" \
  p4c-translator "$@"


