# Quick Deployment Guide — Shared Runner

**Purpose:** Fast setup for deploying the shared macOS runner for the `nelsongrey` organization.

## Zero-Touch Automation

We have a master automation script that handles setup, service management, and monitoring.

```bash
cd ~/Circus/Repositories/nelson-grey
./automate.sh
```

Use the menu to:
1.  **Check Health:** Verify the runner is online.
2.  **Full Setup:** Download and configure the runner (requires token).
3.  **Service Management:** Install, start, or restart the background service.
4.  **Enable Auto-Monitoring:** Add a cron job to auto-recover the runner if it crashes.

## Manual Setup (Alternative)

### Shared Runner (nelson-grey)

This single runner handles builds for `modulo-squares`, `vehicle-vitals`, and `wishlist-wizard`.

```bash
cd ~/Circus/Repositories/nelson-grey

# 1. Run Setup Script
# You will need a registration token from: https://github.com/settings/actions/runners/new (if User) or Organization Settings
chmod +x setup-shared-runner.sh
./setup-shared-runner.sh

# 2. Install & Start Service
cd actions-runner
./svc.sh install
./svc.sh start

# 3. Verify Status
./svc.sh status
```

## Maintenance

### Restarting the Runner
```bash
cd ~/Circus/Repositories/nelson-grey/actions-runner
./svc.sh restart
```

### Checking Logs
Logs are located in `~/Circus/Repositories/nelson-grey/actions-runner/_diag`.

### Updating the Runner
The runner auto-updates itself when GitHub releases a new version. If you need to manually reinstall:
1. Stop the service: `./svc.sh stop`
2. Uninstall the service: `./svc.sh uninstall`
3. Run `./setup-shared-runner.sh` again with the `--replace` flag (included in script).


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

## Troubleshooting

### Service not loading?

```bash
# Check plist path
ls ~/Library/LaunchAgents/actions.runner.*.plist

# Manually load
launchctl load ~/Library/LaunchAgents/actions.runner.mnelson3-nelson-grey.nelson-grey-macos-runner.plist

# Check for errors
launchctl list | grep actions.runner
```

### Runner offline?

```bash
# Check logs
cd ~/Circus/Repositories/nelson-grey/actions-runner
tail -f _diag/*.log
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
