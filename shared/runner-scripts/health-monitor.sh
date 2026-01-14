#!/usr/bin/env bash
set -euo pipefail

# Health monitor for self-hosted macOS runner services.
# Reads runner .service files under runners/<repo>/.service and reports status.
#
# Usage:
#   ./health-monitor.sh                # uses default repo list
#   REPOS="modulo-squares vehicle-vitals" ./health-monitor.sh
#
# Exits non-zero if any service is missing or not loaded.

DEFAULT_REPOS=(modulo-squares vehicle-vitals wishlist-wizard)
REPO_LIST=(${REPOS:-${DEFAULT_REPOS[@]}})
BASE="$HOME/Circus/Repositories/nelson-grey/runners"
OVERALL_STATUS=0

printf "🏥 Runner health check (timestamp: %s)\n" "$(date -Iseconds)"

for repo in "${REPO_LIST[@]}"; do
  SERVICE_FILE="$BASE/$repo/.service"
  if [ ! -f "$SERVICE_FILE" ]; then
    printf "❌ %-18s: missing .service file\n" "$repo"
    OVERALL_STATUS=1
    continue
  fi

  SERVICE_PATH=$(cat "$SERVICE_FILE")
  SERVICE_NAME=$(basename "$SERVICE_PATH" .plist)

  if launchctl list | grep -q "$SERVICE_NAME"; then
    printf "✅ %-18s: active (%s)\n" "$repo" "$SERVICE_NAME"
  else
    printf "❌ %-18s: DOWN (%s)\n" "$repo" "$SERVICE_NAME"
    OVERALL_STATUS=1
  fi

done

exit "$OVERALL_STATUS"
