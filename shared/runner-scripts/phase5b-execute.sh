#!/bin/bash

# Phase 5B Dry-Run Execution & Monitoring Script
# Purpose: Automate secret setup, workflow triggering, and result monitoring
# Usage: ./phase5b-execute.sh [command]

set -e

REPOS=(modulo-squares vehicle-vitals wishlist-wizard stream-control)
OWNER="mnelson3"
TIMEOUT=600  # 10 minutes for test_all; 60 minutes for build_all

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check gh CLI installed
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) not installed"
        exit 1
    fi
    log_success "GitHub CLI installed"
    
    # Check gh authenticated
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI not authenticated. Run: gh auth login"
        exit 1
    fi
    log_success "GitHub CLI authenticated"
    
    # Check jq for JSON parsing
    if ! command -v jq &> /dev/null; then
        log_warn "jq not installed (optional, needed for JSON parsing)"
    fi
}

set_missing_secrets() {
    log_info "Setting MATCH_GIT_BRANCH=main for Flutter projects..."
    
    for repo in modulo-squares vehicle-vitals wishlist-wizard; do
        log_info "Setting secret in ${repo}..."
        gh secret set MATCH_GIT_BRANCH --body "main" -R "${OWNER}/${repo}" 2>/dev/null || \
            log_warn "Failed to set MATCH_GIT_BRANCH in ${repo} (may already exist)"
    done
    
    log_success "Missing secrets configured"
}

trigger_test_all() {
    log_info "Triggering test_all workflows on all 4 repos..."
    
    local run_ids=()
    
    for repo in "${REPOS[@]}"; do
        log_info "Triggering test_all on ${repo}..."
        
        # Trigger workflow
        run_output=$(gh workflow run master-pipeline.yml \
            -f action=test_all \
            -R "${OWNER}/${repo}" 2>&1)
        
        if echo "$run_output" | grep -q "created"; then
            log_success "Triggered test_all on ${repo}"
            
            # Get the run ID
            sleep 2  # Wait for workflow to be created
            run_id=$(gh run list -R "${OWNER}/${repo}" \
                --workflow master-pipeline.yml \
                --limit 1 \
                --json databaseId \
                -q '.[0].databaseId' 2>/dev/null || echo "unknown")
            
            run_ids+=("${repo}:${run_id}")
        else
            log_error "Failed to trigger test_all on ${repo}"
        fi
    done
    
    log_info "Workflow runs:"
    for run in "${run_ids[@]}"; do
        echo "  ${run}"
    done
    
    log_info "Waiting for test_all workflows to complete (max 10 minutes)..."
    monitor_runs "${run_ids[@]}"
}

monitor_runs() {
    local -a run_specs=("$@")
    local elapsed=0
    local interval=30  # Check every 30 seconds
    
    while [[ $elapsed -lt $TIMEOUT ]]; do
        echo ""
        log_info "Status check (${elapsed}s elapsed)..."
        
        local all_done=true
        local all_success=true
        
        for run_spec in "${run_specs[@]}"; do
            IFS=':' read -r repo run_id <<< "$run_spec"
            
            status=$(gh run view "$run_id" -R "${OWNER}/${repo}" \
                --json status -q '.status' 2>/dev/null || echo "unknown")
            
            conclusion=$(gh run view "$run_id" -R "${OWNER}/${repo}" \
                --json conclusion -q '.conclusion' 2>/dev/null || echo "unknown")
            
            case "$status" in
                "completed")
                    if [[ "$conclusion" == "success" ]]; then
                        log_success "${repo}: completed successfully"
                    else
                        log_error "${repo}: completed with status ${conclusion}"
                        all_success=false
                    fi
                    ;;
                "in_progress")
                    log_info "${repo}: still running (conclusion: ${conclusion})..."
                    all_done=false
                    ;;
                *)
                    log_warn "${repo}: status ${status} (conclusion: ${conclusion})"
                    all_done=false
                    ;;
            esac
        done
        
        if [[ "$all_done" == true ]]; then
            if [[ "$all_success" == true ]]; then
                log_success "All workflows completed successfully!"
                return 0
            else
                log_error "Some workflows failed. Check GitHub Actions UI for details."
                return 1
            fi
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    log_error "Timeout reached. Workflows still running after 10 minutes."
    log_info "Check GitHub Actions UI: https://github.com/${OWNER}/<repo>/actions"
    return 1
}

trigger_build_all() {
    log_info "Triggering build_all workflows..."
    log_warn "This will take 30-60 minutes per project. Running sequentially to avoid runner contention."
    
    for repo in "${REPOS[@]}"; do
        log_info "Triggering build_all on ${repo}..."
        
        gh workflow run master-pipeline.yml \
            -f action=build_all \
            -R "${OWNER}/${repo}" 2>&1 | grep -q "created" && \
            log_success "Triggered build_all on ${repo}" || \
            log_error "Failed to trigger build_all on ${repo}"
        
        # Get run ID for monitoring
        sleep 5
        run_id=$(gh run list -R "${OWNER}/${repo}" \
            --workflow master-pipeline.yml \
            --limit 1 \
            --json databaseId \
            -q '.[0].databaseId' 2>/dev/null || echo "unknown")
        
        log_info "Run ID: ${run_id}"
        log_info "Waiting for ${repo} build to complete (max 60 minutes)..."
        
        # Monitor this specific run with longer timeout
        local elapsed=0
        local timeout=3600  # 60 minutes
        local interval=60   # Check every minute
        
        while [[ $elapsed -lt $timeout ]]; do
            status=$(gh run view "$run_id" -R "${OWNER}/${repo}" \
                --json status -q '.status' 2>/dev/null || echo "unknown")
            
            conclusion=$(gh run view "$run_id" -R "${OWNER}/${repo}" \
                --json conclusion -q '.conclusion' 2>/dev/null || echo "unknown")
            
            if [[ "$status" == "completed" ]]; then
                if [[ "$conclusion" == "success" ]]; then
                    log_success "${repo}: build completed successfully"
                    break
                else
                    log_error "${repo}: build failed (conclusion: ${conclusion})"
                    break
                fi
            fi
            
            log_info "${repo}: building... (${elapsed}s elapsed)"
            sleep $interval
            elapsed=$((elapsed + interval))
        done
    done
    
    log_success "All build_all workflows triggered and monitored"
}

show_results() {
    log_info "Build Results Summary"
    echo ""
    
    for repo in "${REPOS[@]}"; do
        log_info "=== ${repo} ==="
        
        gh run list -R "${OWNER}/${repo}" \
            --workflow master-pipeline.yml \
            --limit 3 \
            --json name,status,conclusion,createdAt \
            -q '.[] | "\(.name) [\(.status) \(.conclusion)] \(.createdAt)"' 2>/dev/null || \
            log_warn "Could not fetch runs for ${repo}"
    done
}

show_logs() {
    local repo=$1
    local run_id=$2
    
    if [[ -z "$repo" ]] || [[ -z "$run_id" ]]; then
        log_error "Usage: show_logs <repo> <run_id>"
        return 1
    fi
    
    log_info "Fetching logs for ${repo} run ${run_id}..."
    gh run view "$run_id" -R "${OWNER}/${repo}" --log | head -100
}

usage() {
    cat << EOF
Usage: $0 [command]

Commands:
  prerequisites    Check gh CLI and authentication
  secrets          Set MATCH_GIT_BRANCH=main for Flutter projects
  test_all         Trigger test_all workflows (quick validation)
  build_all        Trigger build_all workflows (full build, 30-60 min each)
  results          Show recent workflow results
  full             Run complete flow: prerequisites → secrets → test_all
  monitor <repo>   Monitor specific repo's current run

Examples:
  $0 prerequisites
  $0 secrets
  $0 test_all           # Start test workflows
  $0 results            # Check results
  $0 build_all          # Start full builds
  $0 monitor modulo-squares
  $0 full               # Complete validation flow

EOF
}

main() {
    local command=${1:-help}
    
    case "$command" in
        prerequisites)
            check_prerequisites
            ;;
        secrets)
            check_prerequisites
            set_missing_secrets
            ;;
        test_all)
            check_prerequisites
            trigger_test_all
            ;;
        build_all)
            check_prerequisites
            trigger_build_all
            ;;
        results)
            check_prerequisites
            show_results
            ;;
        monitor)
            check_prerequisites
            if [[ -z "$2" ]]; then
                log_error "Specify repo name"
                exit 1
            fi
            run_id=$(gh run list -R "${OWNER}/$2" \
                --workflow master-pipeline.yml \
                --limit 1 \
                --json databaseId \
                -q '.[0].databaseId')
            show_logs "$2" "$run_id"
            ;;
        full)
            check_prerequisites
            set_missing_secrets
            trigger_test_all
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            log_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

main "$@"
