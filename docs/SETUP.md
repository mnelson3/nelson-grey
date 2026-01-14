# Zero-Touch CI/CD Setup Guide

**Duration**: ~45 minutes for complete setup  
**Difficulty**: Intermediate  
**Prerequisites**: GitHub CLI, `yq`, `jq`, basic shell knowledge

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Detailed Setup](#detailed-setup)
4. [Validation](#validation)
5. [Troubleshooting](#troubleshooting)
6. [Next Steps](#next-steps)

---

## Prerequisites

### Required Tools

```bash
# GitHub CLI
brew install gh

# YAML processor (for manifest validation)
brew install yq

# JSON processor
brew install jq

# Git
brew install git

# Optional: Docker (for container testing)
brew install docker

# Optional: act (for local workflow testing)
brew install act
```

### GitHub Access

1. **GitHub CLI Authentication**
   ```bash
   gh auth login
   ```
   Choose default options, authenticate with GitHub

2. **Check authentication**
   ```bash
   gh auth status
   ```
   Should show you as authenticated

3. **Organization Access**
   You must have write access to:
   - `mnelson3/modulo-squares`
   - `mnelson3/vehicle-vitals` (or `nelsongrey/vehicle-vitals`)
   - `mnelson3/wishlist-wizard`
   - `mnelson3/nelson-grey`

### Certificates & Keys

You'll need:
- Apple Developer Team ID
- Apple distribution certificate (stored in nelson-grey cert repo)
- ASC private key (p8 format) from App Store Connect
- Android keystore file
- Firebase service account keys

---

## Quick Start

### For Impatient People (5 minutes)

```bash
# 1. Clone infrastructure repo
cd ~/Circus/Repositories
git clone https://github.com/mnelson3/nelson-grey.git
cd nelson-grey

# 2. Verify setup
./shared/runner-scripts/validate-config.sh

# 3. Initialize all projects
./scripts/init-all-projects.sh

# 4. Done!
echo "✅ CI/CD infrastructure ready"
```

**Next step**: Jump to "Validation" section below

---

## Detailed Setup

### Step 1: Verify Nelson-Grey Infrastructure

```bash
cd ~/Circus/Repositories/nelson-grey

# Verify directory structure
ls -la .cicd/
# Expected output:
# drwxr-xr-x projects/
# drwxr-xr-x schemas/
# drwxr-xr-x templates/

# Verify project manifests
ls -la .cicd/projects/
# Expected: modulo-squares.yml, vehicle-vitals.yml, wishlist-wizard.yml

# Verify runner scripts
ls -la shared/runner-scripts/
# Expected: ephemeral-keychain.sh, docker-auth.sh, etc.
```

### Step 2: Setup Secrets in GitHub Organization

Create these organization secrets (Organization Settings → Secrets and variables → Actions):

#### Apple Secrets
```
APPLE_TEAM_ID=<your-team-id>
ASC_KEY_ID=<key-id-from-app-store-connect>
ASC_ISSUER_ID=<issuer-id-from-app-store-connect>
ASC_PRIVATE_KEY=<base64-encoded-p8-key>
```

#### Android Secrets
```
ANDROID_KEYSTORE_PATH=file://path/to/keystore
ANDROID_KEYSTORE_PASSWORD=<password>
ANDROID_KEY_ALIAS=<key-alias>
ANDROID_KEY_PASSWORD=<password>
```

#### Firebase Secrets
```
FIREBASE_TOKEN=<token-from-firebase-login>
FIREBASE_PROJECT_DEV=<dev-project-id>
FIREBASE_PROJECT_STAGING=<staging-project-id>
FIREBASE_PROJECT_PROD=<prod-project-id>
```

#### Docker Secrets (if using)
```
DOCKER_USERNAME=<username>
DOCKER_PASSWORD=<password-or-token>
```

#### Slack (optional)
```
SLACK_WEBHOOK_URL=<webhook-url-for-notifications>
```

### Step 3: Verify Secrets

```bash
# Check which secrets are set
gh secret list --org nelsongrey

# Verify a specific secret is readable
gh secret view APPLE_TEAM_ID --org nelsongrey
```

### Step 4: Configure Project Manifests

The project manifests are already created at:
- `.cicd/projects/modulo-squares.yml`
- `.cicd/projects/vehicle-vitals.yml`
- `.cicd/projects/wishlist-wizard.yml`

Review and customize each:

```bash
# Example: Review modulo-squares manifest
cat .cicd/projects/modulo-squares.yml

# Edit if needed
nano .cicd/projects/modulo-squares.yml
```

Key things to verify:
- ✅ `project.name` matches repository name
- ✅ `targets.ios.signing.team_id` is correct
- ✅ `targets.ios.signing.bundle_id` is correct
- ✅ `ci.runners` are appropriately labeled
- ✅ `ci.triggers` make sense for your workflow

### Step 5: Setup Self-Hosted Runners

#### macOS Runner

```bash
# Navigate to nelson-grey
cd ~/Circus/Repositories/nelson-grey

# Run setup
./scripts/setup-service.sh

# You'll be prompted for:
# 1. GitHub organization (e.g., "nelsongrey")
# 2. Registration token from GitHub

# Get registration token:
# Go to: https://github.com/settings/actions/runners/new
# (or org settings if in an organization)

# The script will:
# - Download GitHub Actions runner
# - Configure it as a service
# - Start the service
# - Add to LaunchAgent for auto-start

# Verify it's running
launchctl list | grep actions.runner

# Verify it's online in GitHub
gh api repos/mnelson3/nelson-grey/actions/runners | jq '.runners[] | {name, status}'
```

#### Docker Runner (Optional)

```bash
# For Docker-based containers
docker run -d \
  --name actions-runner-docker \
  --restart always \
  -e RUNNER_TOKEN="<token-from-github>" \
  -e RUNNER_NAME="docker-runner-1" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ghcr.io/myoung34/github-runner:latest
```

### Step 6: Setup Ephemeral Keychain

The ephemeral keychain script has been fixed to create keychains in the correct location: `~/Library/Keychains/`

Verify the fix is in place:

```bash
# Check the script
grep "KC_DIR=" shared/runner-scripts/ephemeral_keychain_fastlane_fixed.sh

# Should output:
# KC_DIR="$HOME/Library/Keychains"

# NOT:
# KC_DIR="${RUNNER_TEMP:-/tmp}"
```

### Step 7: Test Locally with `act`

```bash
# Test iOS build workflow locally
act -W .github/workflows/reusable/ios-build.yml \
    --input project=modulo-squares \
    --input environment=development

# Test project discovery
act -W .github/workflows/main.yml \
    --input project=modulo-squares
```

### Step 8: Enable Automatic Monitoring

```bash
# Add health check to crontab
CRON_CMD="*/5 * * * * ~/Circus/Repositories/nelson-grey/shared/runner-scripts/health-monitor.sh check"

# Add to crontab
(crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -

# Verify
crontab -l | grep health-monitor.sh
```

---

## Validation

### 1. Validate Project Manifests

```bash
# Validate all projects
./scripts/validate-all-projects.sh

# Expected output:
# ✅ modulo-squares: Configuration valid
# ✅ vehicle-vitals: Configuration valid
# ✅ wishlist-wizard: Configuration valid
```

### 2. Test Runner Connectivity

```bash
# Check if runner is online
./shared/runner-scripts/health-monitor.sh check

# Expected output:
# ✅ macOS runner: ONLINE
# 📊 Jobs completed: 0
# 🚀 Ready for builds
```

### 3. Test Workflow Dispatch

```bash
# Trigger a manual workflow
gh workflow run main.yml \
  --repo mnelson3/modulo-squares \
  --input project=modulo-squares \
  --input environment=development

# Wait and check status
gh run list --repo mnelson3/modulo-squares --limit 1
```

### 4. Monitor Workflow Execution

```bash
# Watch workflow in real-time
gh run watch <run-id> --repo mnelson3/modulo-squares

# Or view in GitHub:
# https://github.com/mnelson3/modulo-squares/actions
```

### 5. Test iOS Build Flow

```bash
# Manually trigger iOS build
gh workflow run ios-build.yml \
  --repo mnelson3/modulo-squares \
  --input release_type=build_only

# Monitor progress
gh run watch --repo mnelson3/modulo-squares
```

---

## Troubleshooting

### Runner Offline

**Problem**: Runner shows "offline" in GitHub

**Solution**:
```bash
# 1. Check service status
launchctl list | grep actions.runner

# 2. Check logs
tail -f ~/Library/Logs/actions.runner.*/service.log

# 3. Restart service
cd ~/Circus/Repositories/nelson-grey/actions-runner
./svc.sh restart

# 4. Check GitHub Actions runner logs
cat _diag/*.log | head -50
```

### Manifest Validation Fails

**Problem**: `validate-config.sh` reports schema errors

**Solution**:
```bash
# Check specific project
yq eval-all '.project' .cicd/projects/modulo-squares.yml

# Compare to schema
yq eval -o json '.definitions.project' .cicd/schemas/project-manifest.schema.json

# Fix issues manually or regenerate from template
cp .cicd/templates/project.template.yml .cicd/projects/my-project.yml
```

### Workflow Not Triggered

**Problem**: Push to develop branch doesn't trigger workflow

**Solution**:
```bash
# 1. Check manifest triggers
grep -A5 "triggers:" .cicd/projects/modulo-squares.yml

# 2. Verify paths match
# - Ensure file changes match "paths" filter

# 3. Check GitHub workflow
cat .github/workflows/main.yml

# 4. Manually trigger as fallback
gh workflow run main.yml --repo mnelson3/modulo-squares --input project=modulo-squares
```

### Ephemeral Keychain Not Found

**Problem**: "Could not locate the provided keychain" error

**Solution**:
```bash
# 1. Verify the script uses ~/Library/Keychains/
grep "KC_DIR=" shared/runner-scripts/ephemeral_keychain_fastlane_fixed.sh
# Should be: KC_DIR="$HOME/Library/Keychains"

# 2. Check if keychain exists
ls -la ~/Library/Keychains/fastlane_tmp_keychain*

# 3. Test keychain creation manually
HOME=/Users/$(whoami) shared/runner-scripts/ephemeral_keychain_fastlane_fixed.sh "echo test"

# 4. Check fastlane match output
# Should say: "Creating temporary keychain: /Users/.../Library/Keychains/fastlane_tmp_keychain.keychain-db"
```

### Workflow Has Dependency Issues

**Problem**: "Expected value not available" in workflow expression

**Solution**:
```bash
# 1. Check all outputs are defined
grep "outputs:" .github/workflows/reusable/ios-build.yml

# 2. Check input names match exactly
# Look for: inputs.project (with dot)
# NOT: ${{ project }}

# 3. Validate workflow YAML
yq eval '.jobs' .github/workflows/main.yml

# 4. Test with act locally first
act -W .github/workflows/main.yml -v
```

---

## Next Steps

### Immediate (Next hour)

- ✅ Run validation scripts
- ✅ Test workflow dispatch manually
- ✅ Monitor first iOS build through to completion

### Short-term (Next day)

- → Update all project .github/workflows to use new reusable templates
- → Test end-to-end: push to develop → build → TestFlight
- → Set up Slack notifications

### Medium-term (Next week)

- → Add health monitoring dashboard
- → Configure auto-recovery
- → Test new project onboarding process
- → Document lessons learned

### Long-term (Ongoing)

- → Monitor success metrics
- → Iterate based on feedback
- → Add new targets/platforms
- → Scale to additional projects

---

## Quick Reference

### Useful Commands

```bash
# Validate all projects
nelson-grey/scripts/validate-all-projects.sh

# Check runner health
nelson-grey/shared/runner-scripts/health-monitor.sh check

# List all runners
gh api repos/mnelson3/modulo-squares/actions/runners | jq '.runners'

# View recent runs
gh run list --repo mnelson3/modulo-squares --limit 10

# Watch a run
gh run watch <run-id> --repo mnelson3/modulo-squares

# View job logs
gh run view <run-id> --repo mnelson3/modulo-squares --log

# Trigger workflow manually
gh workflow run main.yml --repo mnelson3/modulo-squares

# List secrets
gh secret list --org nelsongrey
```

### Directory Structure

```
nelson-grey/
├── .cicd/
│   ├── projects/                      # Project manifests
│   ├── schemas/                       # JSON schemas for validation
│   └── templates/                     # Templates for new projects
├── .github/workflows/
│   ├── main.yml                       # Entry point
│   └── reusable/                      # Workflow templates
├── shared/runner-scripts/             # Shared scripts
├── scripts/                           # Helper scripts
└── docs/                              # Documentation
```

---

## Support

### Debugging Steps

1. **Gather Information**
   ```bash
   # Collect diagnostic info
   ./scripts/diagnose.sh
   ```

2. **Check Logs**
   ```bash
   # Workflow logs in GitHub Actions UI
   # Runner logs at:
   ~/Circus/Repositories/nelson-grey/actions-runner/_diag/
   
   # Service logs:
   tail -f ~/Library/Logs/actions.runner.*/service.log
   ```

3. **Test Components Individually**
   ```bash
   # Test runner connectivity
   ./shared/runner-scripts/health-monitor.sh check
   
   # Test keychain setup
   HOME=/Users/$(whoami) ./shared/runner-scripts/ephemeral_keychain_fastlane_fixed.sh "echo test"
   
   # Test Firebase auth
   ./shared/runner-scripts/firebase-auth.sh test
   ```

4. **Search Documentation**
   - Architecture: [ARCHITECTURE.md](./ARCHITECTURE.md)
   - Troubleshooting: [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
   - Examples: [EXAMPLES.md](./EXAMPLES.md)

---

## Related Documentation

- [Architecture Overview](./ARCHITECTURE.md)
- [Project Manifest Format](./PROJECT_MANIFEST.md)
- [Advanced Troubleshooting](./TROUBLESHOOTING.md)
- [Examples & Recipes](./EXAMPLES.md)
