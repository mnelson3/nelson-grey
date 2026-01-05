#!/bin/bash

# Auto Recover Script for Nelson Grey Multi-Runners
# Restarts any service that is down.

REPOS=("modulo-squares" "vehicle-vitals" "wishlist-wizard")

echo "🚑 Initiating Auto-Recovery..."

for repo in "${REPOS[@]}"; do
    SERVICE_FILE="$HOME/Circus/Repositories/nelson-grey/runners/$repo/.service"
    
    if [ -f "$SERVICE_FILE" ]; then
        PLIST_PATH=$(cat "$SERVICE_FILE")
        SERVICE_NAME=$(basename "$PLIST_PATH" .plist)
        
        if ! launchctl list | grep -q "$SERVICE_NAME"; then
            echo "⚠️  $repo service is down. Attempting restart..."
            
            if [ -f "$PLIST_PATH" ]; then
                launchctl unload "$PLIST_PATH" 2>/dev/null
                sleep 1
                launchctl load "$PLIST_PATH"
                echo "✅ $repo restarted."
            else
                echo "❌ $repo plist not found at $PLIST_PATH"
            fi
        fi
    fi
done
