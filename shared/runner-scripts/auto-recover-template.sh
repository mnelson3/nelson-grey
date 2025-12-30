#!/bin/bash

# Zero-Touch Runner Auto-Recovery (Parameterized Template)
#
# Usage:
#   source auto-recover-template.sh <REPO_OWNER> <REPO_NAME> <RUNNER_NAME> [SCRIPT_DIR]
#   OR
#   ./auto-recover-template.sh <REPO_OWNER> <REPO_NAME> <RUNNER_NAME> [SCRIPT_DIR]
#
# Example:
#   ./auto-recover-template.sh mnelson3 modulo-squares modulo-squares-macos-runner

# Parse arguments
REPO_OWNER="${1:-}"
REPO_NAME="${2:-}"
RUNNER_NAME="${3:-}"
SCRIPT_DIR="${4:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

if [ -z "$REPO_OWNER" ] || [ -z "$REPO_NAME" ] || [ -z "$RUNNER_NAME" ]; then
    echo "❌ Missing arguments"
    echo "Usage: $0 <REPO_OWNER> <REPO_NAME> <RUNNER_NAME> [SCRIPT_DIR]"
    exit 1
fi

SERVICE_NAME="actions.runner.${REPO_OWNER}-${REPO_NAME}.${RUNNER_NAME}"
RUNNER_DIR="$(dirname "$SCRIPT_DIR")"

echo "🔄 Auto-Recovery Started - $(date)"

cd "$RUNNER_DIR"

# Check current health
HEALTH_CHECK_SCRIPT="${SCRIPT_DIR}/health-check-template.sh"
if [ ! -x "$HEALTH_CHECK_SCRIPT" ]; then
    HEALTH_CHECK_SCRIPT="${SCRIPT_DIR}/health-check.sh"
fi

if "$HEALTH_CHECK_SCRIPT" "$REPO_OWNER" "$REPO_NAME" "$RUNNER_NAME" >/dev/null 2>&1; then
    echo "✅ Runner is healthy, no recovery needed"
    exit 0
fi

echo "⚠️ Runner unhealthy, starting recovery..."

# Stop service
echo "🛑 Stopping service..."
sudo launchctl unload "/Library/LaunchDaemons/${SERVICE_NAME}.plist" 2>/dev/null || true

# Kill any remaining processes
echo "💀 Killing processes..."
pkill -9 -f "${RUNNER_NAME}" || true
sleep 3

# Clean configuration
echo "🧹 Cleaning configuration..."
rm -f .credentials* .runner .service

# Get fresh token
echo "🔑 Getting fresh token..."
if ! TOKEN=$(gh api repos/${REPO_OWNER}/${REPO_NAME}/actions/runners/registration-token --jq .token 2>/dev/null); then
    echo "❌ Failed to get token, manual intervention required"
    exit 1
fi

# Reconfigure
echo "⚙️ Reconfiguring runner..."
./config.sh --unattended \
    --url "https://github.com/${REPO_OWNER}/${REPO_NAME}" \
    --token "${TOKEN}" \
    --name "${RUNNER_NAME}" \
    --labels "macos,self-hosted"

# Restart service
echo "🚀 Restarting service..."
sudo launchctl load "/Library/LaunchDaemons/${SERVICE_NAME}.plist"

# Wait and verify
echo "⏳ Waiting for runner to come online..."
sleep 10

if "$HEALTH_CHECK_SCRIPT" "$REPO_OWNER" "$REPO_NAME" "$RUNNER_NAME" >/dev/null 2>&1; then
    echo "✅ Recovery successful!"
    exit 0
else
    echo "❌ Recovery failed, manual intervention required"
    exit 1
fi
