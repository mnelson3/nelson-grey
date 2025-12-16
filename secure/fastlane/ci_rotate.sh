#!/usr/bin/env bash
set -euo pipefail

# CI runner script for rotating certs via fastlane
# Usage: CI should set environment variables (MATCH_GIT_URL, MATCH_PASSWORD, ASC_PRIVATE_KEY, ASC_ISSUER_ID, ASC_KEY_ID, FASTLANE_APPLE_ID)

ROOT_DIR="$(cd "$(dirname "$0")" && cd .. && pwd)"
cd "$ROOT_DIR"

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
  export ASC_PRIVATE_KEY=$(get_var ASC_PRIVATE_KEY)
  export ASC_ISSUER_ID=$(get_var ASC_ISSUER_ID)
  export ASC_KEY_ID=$(get_var ASC_KEY_ID)
  export FASTLANE_APPLE_ID=$(get_var FASTLANE_APPLE_ID)

  echo "Running rotate for project: $project"
  if command -v bundle >/dev/null 2>&1; then
    bundle exec fastlane ci_rotate
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
