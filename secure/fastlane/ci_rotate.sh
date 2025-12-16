#!/usr/bin/env bash
set -euo pipefail

# CI runner script for rotating certs via fastlane
# Usage: CI should set environment variables (MATCH_GIT_URL, MATCH_PASSWORD, ASC_PRIVATE_KEY, ASC_ISSUER_ID, ASC_KEY_ID, FASTLANE_APPLE_ID)

ROOT_DIR="$(cd "$(dirname "$0")" && cd .. && pwd)"
cd "$ROOT_DIR"

# Load .env if present
if [ -f ../.env ]; then
  # shellcheck disable=SC1091
  set -a
  # shellcheck disable=SC1091
  source ../.env
  set +a
fi

echo "Running fastlane ci_rotate from ${ROOT_DIR}"
if command -v bundle >/dev/null 2>&1; then
  bundle exec fastlane ci_rotate
else
  fastlane ci_rotate
fi

echo "fastlane ci_rotate finished"
