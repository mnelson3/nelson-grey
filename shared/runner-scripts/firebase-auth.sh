#!/usr/bin/env bash
set -euo pipefail

# Firebase CLI service account helper.
# Writes the provided service account JSON to a temporary file and exports
# GOOGLE_APPLICATION_CREDENTIALS for downstream Firebase/Google tools.
#
# Usage:
#   FIREBASE_SERVICE_ACCOUNT_JSON="{...}" ./firebase-auth.sh
#   FIREBASE_SERVICE_ACCOUNT_B64="base64..." ./firebase-auth.sh
#   FIREBASE_KEY_PATH=/path/to/key.json ./firebase-auth.sh

TARGET_DIR="${RUNNER_TEMP:-/tmp}"
OUT_PATH="$TARGET_DIR/firebase-key.json"

if [ -n "${FIREBASE_KEY_PATH:-}" ] && [ -f "$FIREBASE_KEY_PATH" ]; then
  OUT_PATH="$FIREBASE_KEY_PATH"
  echo "[firebase-auth] Using existing key at $OUT_PATH"
elif [ -n "${FIREBASE_SERVICE_ACCOUNT_B64:-}" ]; then
  echo "[firebase-auth] Writing service account from base64 to $OUT_PATH"
  echo "$FIREBASE_SERVICE_ACCOUNT_B64" | base64 --decode >"$OUT_PATH"
elif [ -n "${FIREBASE_SERVICE_ACCOUNT_JSON:-}" ]; then
  echo "[firebase-auth] Writing service account JSON to $OUT_PATH"
  echo "$FIREBASE_SERVICE_ACCOUNT_JSON" >"$OUT_PATH"
else
  echo "[firebase-auth] No service account provided. Set FIREBASE_SERVICE_ACCOUNT_JSON or FIREBASE_SERVICE_ACCOUNT_B64 or FIREBASE_KEY_PATH." >&2
  exit 1
fi

python3 - <<'PY'
import json, pathlib, sys
p = pathlib.Path("$OUT_PATH")
try:
    json.loads(p.read_text())
except Exception as exc:
    sys.stderr.write(f"[firebase-auth] Invalid JSON in service account key: {exc}\n")
    sys.exit(2)
PY

export GOOGLE_APPLICATION_CREDENTIALS="$OUT_PATH"
echo "GOOGLE_APPLICATION_CREDENTIALS=$OUT_PATH" >> "${GITHUB_ENV:-/dev/null}" 2>/dev/null || true

echo "[firebase-auth] GOOGLE_APPLICATION_CREDENTIALS set to $OUT_PATH"
