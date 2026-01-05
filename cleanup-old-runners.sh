#!/bin/bash

# Script to uninstall and remove old individual runners

BASE_DIR="$(dirname "$0")/.."
OLD_RUNNERS=(
    "modulo-squares-actions-runner"
    "vehicle-vitals-actions-runner"
    "wishlist-wizard-actions-runner"
)

echo "🧹 Cleaning up old runners..."

for runner in "${OLD_RUNNERS[@]}"; do
    RUNNER_PATH="$BASE_DIR/$runner"
    if [ -d "$RUNNER_PATH" ]; then
        echo "Found $runner at $RUNNER_PATH"
        if [ -f "$RUNNER_PATH/svc.sh" ]; then
            echo "Uninstalling service for $runner..."
            cd "$RUNNER_PATH"
            ./svc.sh stop
            ./svc.sh uninstall
            cd - > /dev/null
        else
            echo "No svc.sh found in $runner, skipping service uninstall."
        fi
        
        echo "You can now safely remove the directory: $RUNNER_PATH"
        # rm -rf "$RUNNER_PATH" # Uncomment to auto-delete
    else
        echo "Directory $runner not found, skipping."
    fi
    echo "-----------------------------------"
done

echo "✅ Cleanup process finished."
echo "Please verify that the new shared runner is active before deleting the old directories."
