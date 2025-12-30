#!/bin/bash

# Zero-Touch Runner Health Check (Parameterized Template)
#
# Usage:
#   source health-check-template.sh <REPO_OWNER> <REPO_NAME> <RUNNER_NAME>
#   OR
#   ./health-check-template.sh <REPO_OWNER> <REPO_NAME> <RUNNER_NAME>
#
# Example:
#   ./health-check-template.sh mnelson3 modulo-squares modulo-squares-macos-runner

# Parse arguments
REPO_OWNER="${1:-}"
REPO_NAME="${2:-}"
RUNNER_NAME="${3:-}"

if [ -z "$REPO_OWNER" ] || [ -z "$REPO_NAME" ] || [ -z "$RUNNER_NAME" ]; then
    echo "❌ Missing arguments"
    echo "Usage: $0 <REPO_OWNER> <REPO_NAME> <RUNNER_NAME>"
    exit 1
fi

SERVICE_NAME="actions.runner.${REPO_OWNER}-${REPO_NAME}.${RUNNER_NAME}"

echo "🏥 Runner Health Check - $(date)"

# Check if service is running
SERVICE_STATUS=$(sudo launchctl list | grep "${SERVICE_NAME}" | awk '{print $1}' || echo "")
if [ -z "$SERVICE_STATUS" ] || [ "$SERVICE_STATUS" = "-" ]; then
    echo "❌ Service not running"
    exit 1
fi

# Check if runner process exists
RUNNER_PID=$(pgrep -f "${RUNNER_NAME}" || echo "")
if [ -z "$RUNNER_PID" ]; then
    echo "❌ Runner process not found"
    exit 1
fi

# Check GitHub status
RUNNER_INFO=$(gh api repos/${REPO_OWNER}/${REPO_NAME}/actions/runners 2>/dev/null | jq -r ".runners[] | select(.name == \"${RUNNER_NAME}\") | {status: .status, busy: .busy}" 2>/dev/null || echo "{}")

if [ "$RUNNER_INFO" = "{}" ]; then
    echo "❌ Runner not found in GitHub"
    exit 1
fi

STATUS=$(echo "$RUNNER_INFO" | jq -r '.status')
BUSY=$(echo "$RUNNER_INFO" | jq -r '.busy')

if [ "$STATUS" != "online" ]; then
    echo "❌ Runner status: $STATUS (expected: online)"
    exit 1
fi

if [ "$BUSY" = "true" ]; then
    echo "⚠️ Runner is busy (this is normal if running jobs)"
fi

echo "✅ Runner healthy - Status: $STATUS, Busy: $BUSY, PID: $RUNNER_PID"
exit 0
