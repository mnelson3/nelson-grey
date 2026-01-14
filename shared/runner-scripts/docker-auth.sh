#!/usr/bin/env bash
set -euo pipefail

# Docker registry login helper for CI runners.
# Usage:
#   DOCKER_USERNAME=... DOCKER_PASSWORD=... ./docker-auth.sh [registry]
#   DOCKER_TOKEN=... ./docker-auth.sh ghcr.io
# Falls back to ghcr.io when registry is not provided.

REGISTRY="${1:-ghcr.io}"
USERNAME="${DOCKER_USERNAME:-${GITHUB_ACTOR:-}}"
PASSWORD="${DOCKER_PASSWORD:-${DOCKER_TOKEN:-}}"

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
  echo "[docker-auth] Missing credentials. Set DOCKER_USERNAME and DOCKER_PASSWORD (or DOCKER_TOKEN)." >&2
  exit 1
fi

echo "[docker-auth] Logging into $REGISTRY as $USERNAME"
# --password-stdin avoids leaking secrets in process list
if ! echo "$PASSWORD" | docker login "$REGISTRY" --username "$USERNAME" --password-stdin; then
  echo "[docker-auth] Docker login failed" >&2
  exit 2
fi

echo "[docker-auth] Login successful"
