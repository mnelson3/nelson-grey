#!/usr/bin/env bash
set -euo pipefail

# Zero-touch runner installer for nelson-grey
# - Downloads GitHub Actions runner v2.330.0
# - Requests registration token (uses gh if available; falls back to NELSON_GREY_PAT in .env)
# - Configures runner unattended with labels
# - Installs and starts runner service
# - Diagnoses common failures and retries (expired tokens, network failures)

REPO_OWNER=mnelson3
REPO_NAME=nelson-grey
WORKDIR="$(dirname "$0")/../actions-runner"
VERSION=2.330.0
NAME="nelson-grey-macos-runner"
LABELS=(self-hosted macOS macos-latest)
MAX_RETRIES=3
SUDO_CMD="sudo"

# Helper: print and mask secrets
mask() { echo "${1:0:8}..."; }

# Determine arch and file
arch=$(uname -m)
if [ "$arch" = "arm64" ]; then
  FILE=actions-runner-osx-arm64-${VERSION}.tar.gz
else
  FILE=actions-runner-osx-x64-${VERSION}.tar.gz
fi

mkdir -p "$WORKDIR"
cd "$WORKDIR"

# Download runner if missing
if [ ! -d "./bin" ]; then
  if [ ! -f "$FILE" ]; then
    echo "Downloading runner $FILE"
    curl -L -o "$FILE" "https://github.com/actions/runner/releases/download/v${VERSION}/${FILE}"
  fi
  echo "Extracting $FILE"
  tar xzf "$FILE"
fi

# Request registration token function
get_token() {
  # Prefer gh CLI
  if command -v gh >/dev/null 2>&1; then
    echo "Requesting registration token via gh"
    if gh auth status >/dev/null 2>&1; then
      token=$(gh api -X POST /repos/${REPO_OWNER}/${REPO_NAME}/actions/runners/registration-token -q .token 2>/dev/null || true)
      # Trim newlines/carriage returns from token
      token=$(printf '%s' "$token" | tr -d '\r\n')
      if [ -n "$token" ] && [ "$token" != "null" ]; then
        echo "$token"
        return 0
      fi
    else
      echo "gh not authenticated"
    fi
  fi

  # Fallback: look for NELSON_GREY_PAT in nearby env files
  # Check runner-manager .env
  if [ -f "$(dirname "$0")/.env" ]; then
    pat=$(grep -E '^NELSON_GREY_PAT=' "$(dirname "$0")/.env" | cut -d'=' -f2- | tr -d '"\r') || true
  fi
  if [ -z "${pat:-}" ] && [ -f ../runner-manager/.env ]; then
    pat=$(grep -E '^NELSON_GREY_PAT=' ../runner-manager/.env | cut -d'=' -f2- | tr -d '"\r') || true
  fi
  if [ -n "${pat:-}" ]; then
    echo "Requesting token using PAT (masked $(mask "$pat"))"
    token=$(curl -s -X POST -H "Authorization: token $pat" -H "Accept: application/vnd.github+json" \
      https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/actions/runners/registration-token | jq -r .token)
    # Trim newlines/carriage returns from token
    token=$(printf '%s' "$token" | tr -d '\r\n')
    if [ -n "$token" ] && [ "$token" != "null" ]; then
      echo "$token"
      return 0
    fi
  fi

  echo ""
  return 1
}

# Configure runner (with retry on token expiry)
configure_runner() {
  local token=$1
  local labels_str
  IFS=','; labels_str="${LABELS[*]}"; unset IFS

  echo "Configuring runner with name=$NAME labels=$labels_str"
  ./config.sh --url https://github.com/${REPO_OWNER}/${REPO_NAME} --token "$token" --name "$NAME" --labels "$labels_str" --work _work --unattended || return 1
  return 0
}

# Install and start service
install_service() {
  if [ -f ./svc.sh ]; then
    echo "Installing runner as service (may require sudo)"
    $SUDO_CMD ./svc.sh install
    $SUDO_CMD ./svc.sh start
  else
    echo "svc.sh not found; runner can be started with ./run.sh"
  fi
}

# Verify registration via API
verify_registration() {
  if command -v gh >/dev/null 2>&1; then
    gh api /repos/${REPO_OWNER}/${REPO_NAME}/actions/runners --jq '.runners[] | {id,name,os,status,labels}'
  else
    echo "Install gh CLI to verify registration programmatically. You can also check in GitHub UI."
  fi
}

# Main flow with retries
attempt=1
while [ $attempt -le $MAX_RETRIES ]; do
  echo "Attempt $attempt/$MAX_RETRIES"
  token="$(get_token || true)"
  if [ -z "$token" ]; then
    echo "Failed to obtain registration token"
    attempt=$((attempt+1))
    sleep 3
    continue
  fi

  # If runner already configured, try to remove old config first
  if [ -f .runner ]; then
    echo "Existing .runner detected; attempting to remove previous config"
    ./config.sh remove --unattended --token "$token" || true
    rm -f .runner || true
  fi

  if configure_runner "$token"; then
    echo "Configured runner successfully"
    install_service || true
    echo "Waiting 5s and verifying registration"
    sleep 5
    verify_registration || true
    echo "Runner setup complete"
    exit 0
  else
    echo "Configuration failed; token may have expired or permissions missing. Retrying..."
    attempt=$((attempt+1))
    sleep 5
    continue
  fi
done

echo "All attempts failed. Collecting logs for diagnosis."
# collect basic logs
echo "-- actions-runner dir contents --"
ls -la
echo "-- runner logs (if any) --"
[ -f runner.log ] && sed -n '1,200p' runner.log || true
[ -d _diag ] && echo "_diag exists" && ls -la _diag | sed -n '1,200p' || true

exit 1
