#!/bin/bash

# Health Check Script for Nelson Grey Multi-Runners
# Verifies that all runner services are active.

REPOS=("modulo-squares" "vehicle-vitals" "wishlist-wizard")

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "🏥 Checking Runners Health..."
OVERALL_STATUS=0

for repo in "${REPOS[@]}"; do
    SERVICE_FILE="$HOME/Circus/Repositories/nelson-grey/runners/$repo/.service"
    
    if [ -f "$SERVICE_FILE" ]; then
        SERVICE_PATH=$(cat "$SERVICE_FILE")
        # Extract the service label from the path (filename without .plist)
        SERVICE_NAME=$(basename "$SERVICE_PATH" .plist)
        
        if launchctl list | grep -q "$SERVICE_NAME"; then
            echo -e "${GREEN}✅ $repo: Service Active ($SERVICE_NAME)${NC}"
        else
            echo -e "${RED}❌ $repo: Service DOWN ($SERVICE_NAME)${NC}"
            OVERALL_STATUS=1
        fi
    else
        echo -e "${RED}❌ $repo: Not installed (No .service file)${NC}"
        OVERALL_STATUS=1
    fi
done

exit $OVERALL_STATUS
