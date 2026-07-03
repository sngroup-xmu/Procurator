#!/usr/bin/env bash
set -euo pipefail

# Run p4c translator's `p4c-translator` inside Docker.
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

# Mount common host paths so input/output paths work regardless of repo location.
#
# - /mnt: WSL drive mounts (legacy)
# - /tmp: intermediate outputs
# - /root,/home: Linux filesystem workspaces
#
# We mount to the same paths inside the container so the translator can consume
# the exact CLI arguments we pass in.
MOUNTS=(-v /tmp:/tmp)
if [[ -d /mnt ]]; then
  MOUNTS+=(-v /mnt:/mnt)
fi
if [[ -d /root ]]; then
  MOUNTS+=(-v /root:/root)
fi
if [[ -d /home ]]; then
  MOUNTS+=(-v /home:/home)
fi

exec docker run --rm \
  "${MOUNTS[@]}" \
  "${IMAGE}" \
  p4c-translator "$@"
