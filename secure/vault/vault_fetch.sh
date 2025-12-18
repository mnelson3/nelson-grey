#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <secret-path> <output-file>"
  exit 2
fi

SECRET_PATH="$1"
OUT="$2"

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# Read from Vault kv v2 at secret/nelson-grey/<SECRET_PATH>
vault kv get -format=json "secret/nelson-grey/$SECRET_PATH" > "$tmp"
value=$(jq -r '.data.data.value' "$tmp")
if [ -z "$value" ] || [ "$value" == "null" ]; then
  echo "Secret not found or empty: secret/nelson-grey/$SECRET_PATH" >&2
  exit 3
fi

echo "$value" | base64 --decode > "$OUT"
chmod 600 "$OUT"
echo "Wrote secret to $OUT"
