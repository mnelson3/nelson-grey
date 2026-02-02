#!/usr/bin/env bash
set -euo pipefail

# CI runner script for rotating certs via fastlane
# Usage: CI should set environment variables (MATCH_GIT_URL, MATCH_PASSWORD, APP_STORE_CONNECT_KEY, APP_STORE_CONNECT_ISSUER_ID, APP_STORE_CONNECT_KEY_ID, FASTLANE_APPLE_ID)

ROOT_DIR="$(cd "$(dirname "$0")" && cd .. && pwd)"
cd "$ROOT_DIR"


  # If token is provided, also set a GIT_ASKPASS helper as a fallback for environments
  # where embedding the token in URL may be modified. This helper prints the token.
  if [[ -n "${MATCH_GIT_URL_TOKEN:-}" ]]; then
    ASKPASS_SCRIPT="$(mktemp -t git_askpass_XXXX.sh)"
    cat > "$ASKPASS_SCRIPT" <<'SH'
#!/usr/bin/env sh
printf '%s' "$1" >/dev/null 2>&1
printf "%s" "${MATCH_GIT_URL_TOKEN}"
SH
    chmod 700 "$ASKPASS_SCRIPT"
    export GIT_ASKPASS="$ASKPASS_SCRIPT"
    export GIT_TERMINAL_PROMPT=0
  fi
# Load .env if present (optional local testing)
if [ -f ../.env ]; then
  # shellcheck disable=SC1091
  set -a
  # shellcheck disable=SC1091
  source ../.env
  set +a
fi

echo "Running fastlane ci_rotate from ${ROOT_DIR}"

# Projects to rotate. Can be a comma-separated list, or set via ROTATE_PROJECTS env.
# Example: ROTATE_PROJECTS="modulo-squares,vehicle-vitals,wishlist-wizard"
ROTATE_PROJECTS=${ROTATE_PROJECTS:-"modulo-squares,vehicle-vitals,wishlist-wizard"}

run_for_project() {
  project=$1
  # normalize project name to env var suffix: replace - with _ and uppercase
  suffix=$(echo "$project" | tr '[:lower:]-' '[:upper:]_' )

  # Helper to read per-project env var or fallback to global
  get_var() {
    local name="$1"
    local per_name="${name}_${suffix}"
    # indirect expansion: first try per-project then global
    eval "val=\"\
      \${${per_name}:-\${${name}:-}}\""
    # Fallback using parameter expansion
    if [ -z "$val" ]; then
      eval "val=\"\${${name}}\""
    fi
    echo "$val"
  }

  export MATCH_GIT_URL=$(get_var MATCH_GIT_URL)
  export MATCH_PASSWORD=$(get_var MATCH_PASSWORD)
  export MATCH_GIT_URL_TOKEN=$(get_var MATCH_GIT_URL_TOKEN)

  app_store_connect_key=$(get_var APP_STORE_CONNECT_KEY)
  app_store_connect_issuer_id=$(get_var APP_STORE_CONNECT_ISSUER_ID)
  app_store_connect_key_id=$(get_var APP_STORE_CONNECT_KEY_ID)

  export APP_STORE_CONNECT_KEY="$app_store_connect_key"
  export APP_STORE_CONNECT_ISSUER_ID="$app_store_connect_issuer_id"
  export APP_STORE_CONNECT_KEY_ID="$app_store_connect_key_id"
  export FASTLANE_APPLE_ID=$(get_var FASTLANE_APPLE_ID)

  # If MATCH_GIT_URL uses HTTPS and a token is provided, embed the token for non-interactive auth
  # trim whitespace and carriage returns from MATCH_GIT_URL
  if [[ -n "${MATCH_GIT_URL}" ]]; then
    MATCH_GIT_URL="$(printf '%s' "$MATCH_GIT_URL" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    export MATCH_GIT_URL
  fi

  if [[ -n "${MATCH_GIT_URL}" && "${MATCH_GIT_URL}" == https://* && -n "${MATCH_GIT_URL_TOKEN:-}" ]]; then
    suf=${MATCH_GIT_URL#https://}
    export MATCH_GIT_URL="https://${MATCH_GIT_URL_TOKEN}@${suf}"
  fi

  # Support SSH deploy key for match cloning (per-project or global)
  SSH_KEY_VAR_NAME="MATCH_SSH_PRIVATE_KEY_${suffix}"
  # prefer per-project then global
  SSH_KEY_VAL=""
  eval "SSH_KEY_VAL=\"\${${SSH_KEY_VAR_NAME}:-\${MATCH_SSH_PRIVATE_KEY:-}}\""
  if [[ -n "$SSH_KEY_VAL" ]]; then
    echo "Found SSH deploy key for project $project; configuring ssh-agent"
    mkdir -p "$HOME/.ssh"
    # create a temp key file
    KEY_FILE="$HOME/.ssh/match_deploy_key_${project}"
    printf '%s' "$SSH_KEY_VAL" > "$KEY_FILE"
    chmod 600 "$KEY_FILE"
    # start ssh-agent and add key
    eval "$(ssh-agent -s)" >/dev/null 2>&1 || true
    ssh-add "$KEY_FILE" >/dev/null 2>&1 || true
    # ensure github known host
    ssh-keyscan -H github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null || true
    # if MATCH_GIT_URL is https, convert to ssh form
    if [[ -n "${MATCH_GIT_URL}" && "${MATCH_GIT_URL}" == https://* ]]; then
      path=${MATCH_GIT_URL#https://github.com/}
      export MATCH_GIT_URL="git@github.com:${path}"
    fi
  fi

  echo "Running rotate for project: $project"
  if command -v bundle >/dev/null 2>&1; then
    # prefer Bundler 2.7.2 for compatibility with the project's Gemfile
    if gem list bundler -i -v 2.7.2 >/dev/null 2>&1; then
      bundle _2.7.2_ exec fastlane ci_rotate
    else
      # attempt to install Bundler 2.7.2 locally then run
      gem install bundler:2.7.2 >/dev/null 2>&1 || true
      bundle _2.7.2_ exec fastlane ci_rotate || fastlane ci_rotate
    fi
  else
    fastlane ci_rotate
  fi
}

# iterate projects
IFS=',' read -ra PROJS <<< "$ROTATE_PROJECTS"
for p in "${PROJS[@]}"; do
  # trim whitespace
  proj=$(echo "$p" | xargs)
  if [ -z "$proj" ]; then
    continue
  fi
  run_for_project "$proj"
done

echo "fastlane ci_rotate finished for all projects"
