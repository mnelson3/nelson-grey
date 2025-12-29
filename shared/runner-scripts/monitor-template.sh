#!/bin/bash

# Zero-Touch Runner Periodic Monitor (Parameterized Template)
# Intended to run via cron or launchd on a schedule (e.g., every 5 minutes)
#
# Usage:
#   source monitor-template.sh <REPO_OWNER> <REPO_NAME> <RUNNER_NAME> [SCRIPT_DIR] [LOG_FILE]
#   OR
#   ./monitor-template.sh <REPO_OWNER> <REPO_NAME> <RUNNER_NAME> [SCRIPT_DIR] [LOG_FILE]
#
# Example:
#   ./monitor-template.sh mnelson3 modulo-squares modulo-squares-macos-runner

# Parse arguments
REPO_OWNER="${1:-}"
REPO_NAME="${2:-}"
RUNNER_NAME="${3:-}"
SCRIPT_DIR="${4:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
LOG_FILE="${5:-${SCRIPT_DIR}/monitor.log}"

if [ -z "$REPO_OWNER" ] || [ -z "$REPO_NAME" ] || [ -z "$RUNNER_NAME" ]; then
    echo "❌ Missing arguments"
    echo "Usage: $0 <REPO_OWNER> <REPO_NAME> <RUNNER_NAME> [SCRIPT_DIR] [LOG_FILE]"
    exit 1
fi

# Append to log with timestamp
log() {
    local msg="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $msg" >> "$LOG_FILE"
}

log "=== Monitor Check Started ==="

# Run health check
HEALTH_CHECK_SCRIPT="${SCRIPT_DIR}/health-check-template.sh"
if [ ! -x "$HEALTH_CHECK_SCRIPT" ]; then
    HEALTH_CHECK_SCRIPT="${SCRIPT_DIR}/health-check.sh"
fi

if "$HEALTH_CHECK_SCRIPT" "$REPO_OWNER" "$REPO_NAME" "$RUNNER_NAME" >> "$LOG_FILE" 2>&1; then
    log "✅ Health check passed"
    exit 0
else
    log "⚠️ Health check failed, triggering auto-recover..."
    
    AUTO_RECOVER_SCRIPT="${SCRIPT_DIR}/auto-recover-template.sh"
    if [ ! -x "$AUTO_RECOVER_SCRIPT" ]; then
        AUTO_RECOVER_SCRIPT="${SCRIPT_DIR}/auto-recover.sh"
    fi
    
    "$AUTO_RECOVER_SCRIPT" "$REPO_OWNER" "$REPO_NAME" "$RUNNER_NAME" "$SCRIPT_DIR" >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
        log "✅ Auto-recovery completed"
    else
        log "❌ Auto-recovery failed"
        exit 1
    fi
fi
