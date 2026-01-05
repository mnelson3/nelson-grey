#!/bin/bash

# Setup script for a single repository runner
# Usage: ./setup-repo-runner.sh <repo-name>

REPO_NAME="$1"
OWNER="mnelson3"
RUNNER_VERSION="2.311.0"
RUNNER_ARCH="osx-arm64"
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNNERS_DIR="$BASE_DIR/runners"
RUNNER_DIR="$RUNNERS_DIR/$REPO_NAME"
REPO_URL="https://github.com/$OWNER/$REPO_NAME"

if [ -z "$REPO_NAME" ]; then
    echo "Usage: $0 <repo-name>"
    exit 1
fi

echo "🚀 Setting up Runner for $REPO_NAME..."

# Create directory
mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

# Download runner if needed
if [ ! -f "config.sh" ]; then
    echo "Downloading runner..."
    curl -o runner.tar.gz -L https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-$RUNNER_ARCH-$RUNNER_VERSION.tar.gz
    tar xzf runner.tar.gz
    rm runner.tar.gz
fi

# Fetch Token
echo "Fetching token..."
TOKEN=$("$BASE_DIR/scripts/get-token.sh" "$REPO_NAME")

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to get token for $REPO_NAME"
    exit 1
fi

# Configure
echo "Configuring..."
# Name: nelson-grey-runner-<repo>
RUNNER_NAME="nelson-grey-runner-$REPO_NAME"

./config.sh --url "$REPO_URL" --token "$TOKEN" --name "$RUNNER_NAME" --labels "self-hosted,macOS,arm64,shared,ios,android" --work "_work" --replace --unattended

# Install Service
echo "Installing Service..."
./svc.sh install
./svc.sh start

echo "✅ $REPO_NAME runner setup complete!"
