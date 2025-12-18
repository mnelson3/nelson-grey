#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <secret-path> <file-to-store>"
  exit 2
fi

SECRET_PATH="$1"   # e.g. secret/data/nelson-grey/asc_private_key
FILE="$2"

if [ ! -f "$FILE" ]; then
  echo "File not found: $FILE" >&2
  exit 3
fi

value=$(base64 -w 0 "$FILE")

# Write to Vault kv v2 at kv/data/nelson-grey/<SECRET_PATH>
vault kv put "secret/nelson-grey/$SECRET_PATH" value="$value"

echo "Stored secret at: secret/nelson-grey/$SECRET_PATH"
