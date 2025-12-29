# Quick Deployment Guide — Zero-Touch Runners

**Purpose:** Fast setup for deploying auto-recovering runners across all projects.

## Quick Start (Per Runner)

### 1. Modulo Squares

```bash
cd ~/Circus/Repositories/modulo-squares-actions-runner

# Bootstrap runner payload (if needed)
chmod +x scripts/bootstrap-runner-payload.sh
./scripts/bootstrap-runner-payload.sh

# Install LaunchDaemon service
chmod +x scripts/setup-service.sh scripts/health-check.sh scripts/auto-recover.sh scripts/monitor.sh
./scripts/setup-service.sh

# Verify
./scripts/health-check.sh
```

### 2. Vehicle Vitals

```bash
cd ~/Circus/Repositories/vehicle-vitals-actions-runner

# Install LaunchDaemon service
chmod +x scripts/setup-service.sh scripts/health-check.sh scripts/auto-recover.sh scripts/monitor.sh
./scripts/setup-service.sh

# Verify
./scripts/health-check.sh
```

### 3. Wishlist Wizard

```bash
cd ~/Circus/Repositories/wishlist-wizard-actions-runner

# Already has complete scripts; just ensure permissions
chmod +x scripts/setup-service.sh scripts/health-check.sh scripts/auto-recover.sh scripts/monitor.sh

# If re-installing service
./scripts/setup-service.sh

# Verify
./scripts/health-check.sh
```

## Verification Checklist

After setup, verify each runner:

```bash
# Check service is loaded
sudo launchctl list | grep "actions.runner.mnelson3"

# Check runner is online
./scripts/health-check.sh
# Expected: ✅ Runner healthy - Status: online

# Check service logs
tail -f service.log
```

## Enable Periodic Monitoring

Add to macOS crontab (run `crontab -e`):

```bash
# Monitor all runners every 5 minutes
*/5 * * * * /path/to/modulo-squares-actions-runner/scripts/monitor.sh >/dev/null 2>&1
*/5 * * * * /path/to/vehicle-vitals-actions-runner/scripts/monitor.sh >/dev/null 2>&1
*/5 * * * * /path/to/wishlist-wizard-actions-runner/scripts/monitor.sh >/dev/null 2>&1
```

## Troubleshooting

### Service not loading?

```bash
# Check plist path
ls /Library/LaunchDaemons/actions.runner.*.plist

# Manually load
sudo launchctl load /Library/LaunchDaemons/actions.runner.mnelson3-modulo-squares.modulo-squares-macos-runner.plist

# Check for errors
sudo launchctl list | grep actions.runner
```

### Runner offline?

```bash
# Manual recovery
./scripts/auto-recover.sh

# Check logs
tail -f scripts/monitor.log
```

### GitHub CLI authentication issue?

```bash
# Verify auth
gh auth status

# Re-authenticate if needed
gh auth login

# Then retry setup
./scripts/setup-service.sh
```

## Useful Commands

```bash
# Check all runner services
sudo launchctl list | grep actions.runner

# View runner service log
tail -f ~/Library/Logs/actions.runner.*/service.log

# Manually run health check
{repo}/scripts/health-check.sh

# Manually run recovery
{repo}/scripts/auto-recover.sh

# View monitor log
tail -f {repo}/scripts/monitor.log

# Check GitHub runner status
gh api repos/mnelson3/{REPO}/actions/runners | jq '.runners[] | {name, status}'
```

## Verify End-to-End iOS Build

After runners are deployed:

1. **Push a tag or branch** that triggers iOS build workflow
2. **Monitor workflow** in GitHub Actions
3. **Verify runner picks up job** (check `{repo}-macos-runner` takes it)
4. **Confirm build succeeds** with signing certs from `nelson-grey/certs`
5. **Verify app uploaded** to App Store Connect

Example: Push tag `v1.0.0` to trigger release build.

---

**Status:** All runners ready for production iOS distribution!
