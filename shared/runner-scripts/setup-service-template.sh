#!/bin/bash

# Zero-Touch LaunchDaemon Runner Setup (Parameterized Template)
# 
# Usage:
#   source setup-service-template.sh <REPO_OWNER> <REPO_NAME> <RUNNER_NAME>
#   OR
#   ./setup-service-template.sh <REPO_OWNER> <REPO_NAME> <RUNNER_NAME>
#
# Example:
#   ./setup-service-template.sh mnelson3 modulo-squares modulo-squares-macos-runner

set -e

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
PLIST_PATH="/Library/LaunchDaemons/${SERVICE_NAME}.plist"

echo "🚀 Zero-Touch Runner Setup"
echo "=========================="
echo "📋 Configuration:"
echo "  Repository: ${REPO_OWNER}/${REPO_NAME}"
echo "  Runner: ${RUNNER_NAME}"
echo "  Service: ${SERVICE_NAME}"

# Stop any existing processes
echo "🛑 Stopping existing processes..."
pkill -f "${RUNNER_NAME}" || true
sleep 2

# Clean configuration
echo "🧹 Cleaning old configuration..."
cd "$(dirname "$0")/.."
rm -f .credentials* .runner .service

# Get token
echo "🔑 Getting registration token..."
if ! TOKEN=$(gh api repos/${REPO_OWNER}/${REPO_NAME}/actions/runners/registration-token --jq .token 2>/dev/null); then
    echo "⚠️ GitHub CLI token retrieval failed. Please provide token manually:"
    echo "   Visit: https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/actions/runners"
    echo "   Click 'New self-hosted runner' and copy the token"
    read -p "Enter registration token: " TOKEN
    if [ -z "$TOKEN" ]; then
        echo "❌ No token provided. Exiting."
        exit 1
    fi
fi
echo "✅ Token obtained"

# Configure runner
echo "⚙️ Configuring runner..."
./config.sh --unattended \
    --url "https://github.com/${REPO_OWNER}/${REPO_NAME}" \
    --token "${TOKEN}" \
    --name "${RUNNER_NAME}" \
    --labels "macos,self-hosted"

# Create service plist
echo "📄 Creating service plist..."
RUNNER_PWD="$(pwd)"
sudo tee "${PLIST_PATH}" > /dev/null << PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${SERVICE_NAME}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${RUNNER_PWD}/run.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    <key>WorkingDirectory</key>
    <string>${RUNNER_PWD}</string>
    <key>StandardOutPath</key>
    <string>${RUNNER_PWD}/service.log</string>
    <key>StandardErrorPath</key>
    <string>${RUNNER_PWD}/service.err</string>
    <key>UserName</key>
    <string>$(whoami)</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
</dict>
</plist>
PLIST_EOF

# Load service
echo "🚀 Loading service..."
sudo launchctl unload "${PLIST_PATH}" 2>/dev/null || true
sudo launchctl load "${PLIST_PATH}"

echo "✅ Service setup complete!"
echo "📊 Service status: $(sudo launchctl list | grep "${SERVICE_NAME}" || echo "Not loaded yet")"
