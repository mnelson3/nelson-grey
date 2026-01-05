#!/bin/bash

# 🚀 Nelson Grey - Zero-Touch Runner Automation
# This script handles the full lifecycle of the shared macOS runner.

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER_DIR="$SCRIPT_DIR/actions-runner"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

echo -e "${BLUE}🤖 Nelson Grey Zero-Touch Automation${NC}"
echo "========================================"

# Function to check status
check_status() {
    echo -e "\n${YELLOW}🔍 Checking Status...${NC}"
    if [ -f "$SCRIPTS_DIR/health-check.sh" ]; then
        "$SCRIPTS_DIR/health-check.sh"
    else
        echo "Health check script not found."
    fi
}

# Function to setup runner
setup_runner() {
    echo -e "\n${BLUE}🛠️  Setting up Runners...${NC}"
    
    REPOS=("modulo-squares" "vehicle-vitals" "wishlist-wizard")
    
    for repo in "${REPOS[@]}"; do
        echo -e "\nProcessing $repo..."
        "$SCRIPT_DIR/setup-repo-runner.sh" "$repo"
    done
}

# Function to install/start service
manage_service() {
    echo -e "\n${BLUE}⚙️  Managing Services...${NC}"
    
    echo "1. Restart All Services"
    echo "2. Stop All Services"
    echo "3. Start All Services"
    echo "4. Back to Menu"
    read -p "Select option: " choice
    
    REPOS=("modulo-squares" "vehicle-vitals" "wishlist-wizard")
    
    case $choice in
        1) 
            for repo in "${REPOS[@]}"; do
                echo "Restarting $repo..."
                cd "$SCRIPT_DIR/runners/$repo" && ./svc.sh restart
            done
            ;;
        2)
            for repo in "${REPOS[@]}"; do
                echo "Stopping $repo..."
                cd "$SCRIPT_DIR/runners/$repo" && ./svc.sh stop
            done
            ;;
        3)
            for repo in "${REPOS[@]}"; do
                echo "Starting $repo..."
                cd "$SCRIPT_DIR/runners/$repo" && ./svc.sh start
            done
            ;;
        *) ;;
    esac
    cd "$SCRIPT_DIR"
}

# Function to setup monitoring
setup_monitoring() {
    echo -e "\n${BLUE}⏱️  Setting up Cron Monitoring...${NC}"
    CRON_CMD="*/5 * * * * $SCRIPTS_DIR/monitor.sh >/dev/null 2>&1"
    
    # Check if already exists
    if crontab -l 2>/dev/null | grep -q "nelson-grey/scripts/monitor.sh"; then
        echo -e "${GREEN}✅ Monitoring already configured in crontab.${NC}"
    else
        (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
        echo -e "${GREEN}✅ Added monitoring to crontab.${NC}"
    fi
}

# Main Menu
while true; do
    echo -e "\n${BLUE}Select an action:${NC}"
    echo "1. 🏥 Check Health"
    echo "2. 🚀 Full Setup (Download & Configure)"
    echo "3. ⚙️  Service Management (Start/Stop/Install)"
    echo "4. ⏱️  Enable Auto-Monitoring (Cron)"
    echo "5. 🧹 Cleanup Old Runners"
    echo "q. Quit"
    
    read -p "Enter choice: " choice
    
    case $choice in
        1) check_status ;;
        2) setup_runner ;;
        3) manage_service ;;
        4) setup_monitoring ;;
        5) "$SCRIPT_DIR/cleanup-old-runners.sh" ;;
        q) exit 0 ;;
        *) echo "Invalid option" ;;
    esac
done
