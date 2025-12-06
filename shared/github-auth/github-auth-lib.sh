#!/bin/bash

# Shared GitHub CLI Authentication Library
# Provides standardized, zero-touch GitHub Actions runner token management
# Version: 1.0.0

set -e

# Configuration
SCRIPT_VERSION="1.0.0"
REQUIRED_GH_VERSION="2.40.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "${LOG_FILE:-/tmp/github-auth.log}"
    echo "[$timestamp] [$level] $message"
}

log_info() { log "INFO" "$1"; }
log_warn() { log "WARN" "$1"; }
log_error() { log "ERROR" "$1"; }

# Check if GitHub CLI is installed and authenticated
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed"
        log_error "Install from: https://cli.github.com/"
        return 1
    fi

    # Check version
    local gh_version
    gh_version=$(gh --version | head -1 | awk '{print $3}')
    if ! version_compare "$gh_version" "$REQUIRED_GH_VERSION"; then
        log_warn "GitHub CLI version $gh_version may be outdated (recommended: $REQUIRED_GH_VERSION+)"
    fi

    # Check authentication
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI is not authenticated"
        log_error "Run: gh auth login"
        return 1
    fi

    log_info "GitHub CLI authenticated and ready"
    return 0
}

# Version comparison function
version_compare() {
    local version="$1"
    local required="$2"

    # Simple version comparison (major.minor.patch)
    local v1_parts=(${version//./ })
    local v2_parts=(${required//./ })

    for i in {0..2}; do
        local v1_part=${v1_parts[$i]:-0}
        local v2_part=${v2_parts[$i]:-0}

        if (( v1_part > v2_part )); then
            return 0
        elif (( v1_part < v2_part )); then
            return 1
        fi
    done

    return 0
}

# Get current authenticated user
get_gh_user() {
    gh api user --jq '.login' 2>/dev/null
}

# Validate repository access
validate_repo_access() {
    local owner="$1"
    local repo="$2"

    if ! gh repo view "$owner/$repo" &> /dev/null; then
        log_error "No access to repository: $owner/$repo"
        log_error "Ensure you have admin access to manage runners"
        return 1
    fi

    log_info "Repository access validated: $owner/$repo"
    return 0
}

# Generate new runner registration token
generate_runner_token() {
    local owner="$1"
    local repo="$2"

    # Log without echoing to stdout
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Generating new runner registration token for $owner/$repo" >> "${LOG_FILE:-/tmp/github-auth.log}"

    local token
    token=$(gh api -X POST "repos/$owner/$repo/actions/runners/registration-token" --jq '.token' 2>/dev/null)

    if [ -z "$token" ] || [ "$token" = "null" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] Failed to generate runner token" >> "${LOG_FILE:-/tmp/github-auth.log}"
        return 1
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Runner token generated successfully" >> "${LOG_FILE:-/tmp/github-auth.log}"
    # Only output the token, no logging to stdout
    echo "$token"
}

# Check if token is expired or about to expire
is_token_expired() {
    local token="$1"
    local buffer_minutes="${2:-5}"  # Default 5 minute buffer

    # If no token provided, consider it expired
    if [ -z "$token" ] || [ "$token" = "null" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] No token provided, considering expired" >> "${LOG_FILE:-/tmp/github-auth.log}"
        return 0  # Expired
    fi

    # GitHub runner tokens expire after 1 hour (60 minutes)
    # We'll consider it expired if it has less than buffer_minutes remaining

    # For now, we'll use a simple time-based check
    # In a real implementation, you might want to test the token validity
    local token_age_minutes=0

    # If no token file modification time available, assume expired
    if [ -n "$ENV_FILE" ] && [ -f "$ENV_FILE" ]; then
        local token_mtime
        token_mtime=$(stat -f %m "$ENV_FILE" 2>/dev/null || stat -c %Y "$ENV_FILE" 2>/dev/null || echo "0")
        local current_time
        current_time=$(date +%s)
        token_age_minutes=$(( (current_time - token_mtime) / 60 ))
    fi

    # Tokens are valid for 60 minutes, refresh with buffer
    if [ "$token_age_minutes" -ge $((60 - buffer_minutes)) ]; then
        return 0  # Expired (true)
    else
        return 1  # Not expired (false)
    fi
}

# Update token in environment file
update_token_in_file() {
    local token="$1"
    local env_file="$2"

    if [ ! -f "$env_file" ]; then
        log_error "Environment file not found: $env_file"
        return 1
    fi

    # Create backup
    cp "$env_file" "${env_file}.bak"

    # Update RUNNER_TOKEN - use a simple and robust approach
    local temp_file="${env_file}.tmp"
    local updated=false

    # Read the file line by line and update the token
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ $line =~ ^RUNNER_TOKEN= ]]; then
            echo "RUNNER_TOKEN=$token" >> "$temp_file"
            updated=true
        else
            echo "$line" >> "$temp_file"
        fi
    done < "$env_file"

    # If RUNNER_TOKEN line didn't exist, add it
    if [ "$updated" = false ]; then
        echo "RUNNER_TOKEN=$token" >> "$temp_file"
    fi

    # Replace the original file
    mv "$temp_file" "$env_file"

    log_info "Updated RUNNER_TOKEN in $env_file"
    return 0
}

# Test token validity
test_token() {
    local owner="$1"
    local repo="$2"
    local token="$3"

    # Log without echoing to stdout
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Testing token validity for $owner/$repo" >> "${LOG_FILE:-/tmp/github-auth.log}"

    # Runner registration tokens cannot be used for API authentication
    # Instead, we validate by checking if the token is non-empty and properly formatted
    if [ -z "$token" ] || [ "$token" = "null" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] Token is empty or null" >> "${LOG_FILE:-/tmp/github-auth.log}"
        return 1
    fi

    # Basic format validation (GitHub tokens are typically 29+ characters)
    if [ ${#token} -lt 20 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] Token appears to be malformed (too short)" >> "${LOG_FILE:-/tmp/github-auth.log}"
        return 1
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Token format validation passed" >> "${LOG_FILE:-/tmp/github-auth.log}"
    return 0
}

# Main token refresh function
refresh_runner_token() {
    local owner="$1"
    local repo="$2"
    local env_file="$3"

    log_info "Starting token refresh for $owner/$repo"

    # Validate prerequisites
    check_gh_cli || return 1
    validate_repo_access "$owner" "$repo" || return 1

    # Generate new token
    local new_token
    new_token=$(generate_runner_token "$owner" "$repo")
    if [ $? -ne 0 ]; then
        log_error "Failed to generate new token"
        return 1
    fi

    # Test the new token
    test_token "$owner" "$repo" "$new_token" || {
        log_error "Generated token is invalid"
        return 1
    }

    # Update environment file
    update_token_in_file "$new_token" "$env_file" || {
        log_error "Failed to update environment file"
        return 1
    }

    log_info "Token refresh completed successfully"
    return 0
}

# Setup function for initial configuration
setup_auth() {
    local owner="$1"
    local repo="$2"

    echo -e "${BLUE}🔧 GitHub CLI Authentication Setup${NC}"
    echo "=================================="
    echo ""

    # Check prerequisites
    if ! check_gh_cli; then
        echo -e "${YELLOW}📋 Setup Instructions:${NC}"
        echo "1. Install GitHub CLI: https://cli.github.com/"
        echo "2. Authenticate: gh auth login"
        echo "3. Run this setup again"
        return 1
    fi

    # Validate repository access
    if ! validate_repo_access "$owner" "$repo"; then
        echo -e "${RED}❌ Repository access validation failed${NC}"
        echo -e "${YELLOW}Ensure you have admin access to: https://github.com/$owner/$repo${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ GitHub CLI authentication configured successfully${NC}"
    echo ""
    echo -e "${BLUE}🎯 Zero-touch operation enabled!${NC}"
    echo "Tokens will be refreshed automatically via launch agents"
    return 0
}

# Export functions for use in other scripts
export -f log log_info log_warn log_error
export -f check_gh_cli get_gh_user validate_repo_access
export -f generate_runner_token is_token_expired
export -f update_token_in_file test_token refresh_runner_token setup_auth
