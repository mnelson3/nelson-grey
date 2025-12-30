#!/usr/bin/env bash
set -euo pipefail

# register_runner.sh
# Requests a short-lived runner registration token from the runner-manager
# and optionally runs the GitHub Actions runner `config.sh` to register
# the runner. Intended to be run on the self-hosted runner host.

usage() {
  cat <<EOF
Usage: $0 --owner OWNER --repo REPO [--runner-dir RUNNER_DIR] [--auto]

Environment variables:
  RUNNER_MANAGER_URL   URL to runner-manager (default: http://localhost:3000)
  RUNNER_MANAGER_API_KEY  API key (or set via env RUNNER_MANAGER_API_KEY)

Options:
  --owner OWNER        GitHub owner (user or org)
  --repo REPO          Repository name
  --runner-dir DIR     Path to the Actions runner directory containing config.sh
  --auto               Automatically run config script to register the runner
  -h, --help           Show this help

Examples:
  RUNNER_MANAGER_URL=https://runners.example.com RUNNER_MANAGER_API_KEY=xxx \
    $0 --owner my-org --repo my-repo --runner-dir /opt/actions-runner --auto

EOF
}

OWNER=""
REPO=""
RUNNER_DIR=""
AUTO=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner) OWNER="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    --runner-dir) RUNNER_DIR="$2"; shift 2 ;;
    --auto) AUTO=true; shift 1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$OWNER" || -z "$REPO" ]]; then
  echo "--owner and --repo are required" >&2
  usage
  exit 2
fi

RM_URL=${RUNNER_MANAGER_URL:-http://localhost:3000}
# API key may be provided via env `RUNNER_MANAGER_API_KEY` or via a file path in
# `RUNNER_MANAGER_API_KEY_FILE`. Default file path is /etc/nelson-grey/runner-manager/api_key
API_KEY=${RUNNER_MANAGER_API_KEY:-""}
# Prefer an in-repo/local file by default to avoid referencing /etc paths.
# `SCRIPT_DIR` is the directory containing this script (runner-manager).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_KEY_FILE=${RUNNER_MANAGER_API_KEY_FILE:-"$SCRIPT_DIR/api_key"}

if [[ -z "$API_KEY" && -f "$API_KEY_FILE" ]]; then
  API_KEY=$(cat "$API_KEY_FILE" | tr -d '\n' || true)
fi

if [[ -z "$API_KEY" ]]; then
  echo "RUNNER_MANAGER_API_KEY must be set in environment or available at $API_KEY_FILE" >&2
  echo "You can create the file inside the project and restrict permissions:" >&2
  echo "  mkdir -p \$(dirname $API_KEY_FILE) && echo '<key>' > $API_KEY_FILE && chmod 600 $API_KEY_FILE" >&2
  exit 2
fi

echo "Requesting registration token from $RM_URL for $OWNER/$REPO"

RESP=$(curl -sS -H "Content-Type: application/json" -H "X-API-KEY: ${API_KEY}" \
  -X POST --data "{\"owner\":\"${OWNER}\",\"repo\":\"${REPO}\"}" \
  "${RM_URL%/}/register-runner")

if [[ -z "$RESP" ]]; then
  echo "Empty response from runner-manager" >&2
  exit 3
fi

# extract token and expires_at using jq if available, otherwise Python
if command -v jq >/dev/null 2>&1; then
  TOKEN=$(echo "$RESP" | jq -r '.token // empty')
  EXPIRES_AT=$(echo "$RESP" | jq -r '.expires_at // empty')
else
  TOKEN=$(python3 - <<PY
import sys, json
try:
  data=json.load(sys.stdin)
  print(data.get('token',''))
except Exception:
  sys.exit(1)
PY
  <<<"$RESP")
  EXPIRES_AT=$(python3 - <<PY
import sys, json
try:
  data=json.load(sys.stdin)
  print(data.get('expires_at',''))
except Exception:
  sys.exit(1)
PY
  <<<"$RESP")
fi

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "Failed to obtain token from runner-manager. Response: $RESP" >&2
  exit 4
fi

echo "Received token (masked): ${TOKEN:0:8}... expires: ${EXPIRES_AT:-unknown}"

TOKEN_FILE="./runner_registration_token.txt"
echo "$TOKEN" > "$TOKEN_FILE"
chmod 600 "$TOKEN_FILE"

if [[ "$AUTO" == true && -n "$RUNNER_DIR" ]]; then
  CONFIG_SH="$RUNNER_DIR/config.sh"
  if [[ ! -x "$CONFIG_SH" ]]; then
    echo "Config script not found or not executable at $CONFIG_SH" >&2
    exit 5
  fi

  RUNNER_URL="https://github.com/${OWNER}/${REPO}"
  RUNNER_NAME="$(hostname)-$(date +%s)"

  echo "Running runner config to register: $CONFIG_SH --url $RUNNER_URL --token *** --unattended --replace --name $RUNNER_NAME"

  (cd "$RUNNER_DIR" && sudo "$CONFIG_SH" --url "$RUNNER_URL" --token "$TOKEN" --unattended --replace --name "$RUNNER_NAME")
  echo "Runner registration attempted. Check runner service logs for success." 
else
  echo "Token saved to $TOKEN_FILE. To register manually run the runner config with this token." 
  echo "Example (from runner dir): ./config.sh --url https://github.com/${OWNER}/${REPO} --token \\$(cat $TOKEN_FILE) --unattended --replace --name $(hostname)-TIMESTAMP"
fi

exit 0
