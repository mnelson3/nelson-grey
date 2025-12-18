#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
MATCH_REPO_DIR="$ROOT_DIR/match_repo"

echo "This script bootstraps a local encrypted match repo for prototyping."
echo "It does NOT store secrets securely — use a real secret manager for production."

mkdir -p "$MATCH_REPO_DIR"
cd "$MATCH_REPO_DIR"

if [ ! -d .git ]; then
  git init -b main
  echo ".gitkeep" > README.md
  git add README.md
  git commit -m "init match repo placeholder"
fi

echo "Created placeholder match repo at: $MATCH_REPO_DIR"
echo "Update fastlane/Matchfile git_url to point to this (or a remote encrypted repo)."

exit 0
