#!/usr/bin/env bash
set -euo pipefail

usage() { echo "Usage: $0 <lane>"; exit 2; }
[ "$#" -ge 1 ] || usage
LANE="$1"

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

# Optionally fetch secrets from Vault before running match
# Example environment variables used by fastlane:
#  - ASC_PRIVATE_KEY_PATH -> path to .p8 file
#  - MATCH_PASSWORD -> passphrase for match repo
if [ -n "${VAULT_ADDR:-}" ] && [ -n "${VAULT_TOKEN:-}" ]; then
  echo "Vault detected. Trying to fetch asc_private_key and match_passphrase from Vault..."
  if [ -x "$ROOT_DIR/vault/vault_fetch.sh" ]; then
    mkdir -p .secrets
    "$ROOT_DIR/vault/vault_fetch.sh" asc_private_key .secrets/AuthKey.p8 || true
    "$ROOT_DIR/vault/vault_fetch.sh" match_passphrase .secrets/match_passphrase.txt || true
    if [ -f .secrets/AuthKey.p8 ]; then
      export ASC_PRIVATE_KEY_PATH="${HOME}/.private_keys/AuthKey_match.p8"
      mkdir -p "${HOME}/.private_keys"
      cp .secrets/AuthKey.p8 "${ASC_PRIVATE_KEY_PATH}"
      export ASC_PRIVATE_KEY=$(base64 -w0 .secrets/AuthKey.p8)
    fi
    if [ -f .secrets/match_passphrase.txt ]; then
      export MATCH_PASSWORD=$(cat .secrets/match_passphrase.txt)
    fi
  fi
fi

if [ ! -f Gemfile.lock ]; then
  echo "Installing bundler gems..."
  bundle install --path .bundle
fi

echo "Running fastlane lane: $LANE"
# Example: supply App Store Connect API key via environment variable FASTLANE_APPLE_APPLICATION_SPECIFIC or via file
bundle exec fastlane ios $LANE
