#!/bin/bash

# Get Runner Registration Token
# Uses GitHub CLI to fetch a token for a specific repository

REPO_NAME="$1"
OWNER="mnelson3"

if [ -z "$REPO_NAME" ]; then
    echo "Usage: $0 <repo-name>" >&2
    exit 1
fi

# Check for gh CLI
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not found." >&2
    exit 1
fi

# Try Repo Endpoint
TOKEN=$(gh api -X POST "repos/$OWNER/$REPO_NAME/actions/runners/registration-token" --jq '.token' 2>/dev/null)

if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    echo "$TOKEN"
    exit 0
fi

echo "❌ Could not fetch token for $OWNER/$REPO_NAME" >&2
exit 1
