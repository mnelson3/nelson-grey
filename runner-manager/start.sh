#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR/runner-manager"

# If Vault is available, fetch the GitHub App private key into .secrets/
if [ -n "${VAULT_ADDR:-}" ] && [ -n "${VAULT_TOKEN:-}" ]; then
  echo "Fetching GitHub App private key from Vault..."
  mkdir -p .secrets
  ../../secure/vault/vault_fetch.sh github_app_private_key .secrets/github_app_key.pem || true
  if [ -f .secrets/github_app_key.pem ]; then
    export GITHUB_APP_PRIVATE_KEY_PATH="$ROOT_DIR/runner-manager/.secrets/github_app_key.pem"
  fi
fi

echo "Starting Runner Manager..."
npm start
