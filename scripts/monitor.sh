#!/bin/bash

# Monitor Script for Nelson Grey Shared Runner
# Intended to be run via cron. Checks health and recovers if needed.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/monitor.log"

# Timestamp
echo "[$(date)] Monitoring check started..." >> "$LOG_FILE"

# Run Health Check
"$SCRIPT_DIR/health-check.sh" >> "$LOG_FILE" 2>&1
HEALTH_STATUS=$?

if [ $HEALTH_STATUS -ne 0 ]; then
    echo "[$(date)] ⚠️ Health check failed (Code: $HEALTH_STATUS). Attempting recovery..." >> "$LOG_FILE"
    "$SCRIPT_DIR/auto-recover.sh" >> "$LOG_FILE" 2>&1
else
    echo "[$(date)] ✅ System healthy." >> "$LOG_FILE"
fi
