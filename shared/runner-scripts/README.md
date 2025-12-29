# Zero-Touch Runner Scripts (Shared)

This directory contains parameterized, reusable scripts for zero-touch GitHub Actions runner management. These templates are used by all runner repos (`modulo-squares-actions-runner`, `vehicle-vitals-actions-runner`, `wishlist-wizard-actions-runner`) to provide consistent behavior.

## Overview

Each script supports both **parameterized template mode** (where repo details are passed as arguments) and **direct instantiation** (where repos create their own copies with hardcoded values).

### Scripts

#### `setup-service-template.sh`
Installs a GitHub Actions runner as a persistent macOS LaunchDaemon service.

**Features:**
- Automatic token retrieval via GitHub CLI (with fallback to manual entry)
- Runner configuration and registration
- LaunchDaemon plist creation with `KeepAlive` (auto-restart on crash)
- Starts at system boot

**Usage:**
```bash
./setup-service-template.sh <REPO_OWNER> <REPO_NAME> <RUNNER_NAME>
```

**Example:**
```bash
./setup-service-template.sh mnelson3 modulo-squares modulo-squares-macos-runner
```

#### `health-check-template.sh`
Verifies runner health across three dimensions: service status, process status, and GitHub API status.

**Checks:**
1. LaunchDaemon service is loaded and running
2. Runner process exists (via `pgrep`)
3. GitHub reports runner as `online`

**Usage:**
```bash
./health-check-template.sh <REPO_OWNER> <REPO_NAME> <RUNNER_NAME>
```

**Exit codes:**
- `0`: Healthy
- `1`: Unhealthy

#### `auto-recover-template.sh`
Attempts automatic recovery when health check fails. Sequence:
1. Stops the service
2. Kills any remaining processes
3. Cleans runner configuration
4. Obtains fresh GitHub registration token
5. Reconfigures runner
6. Restarts service
7. Verifies recovery

**Usage:**
```bash
./auto-recover-template.sh <REPO_OWNER> <REPO_NAME> <RUNNER_NAME> [SCRIPT_DIR]
```

#### `monitor-template.sh`
Periodic monitoring script (runs every 5 minutes via cron or launchd). Calls `health-check`, and if unhealthy, triggers `auto-recover`. Logs all activity.

**Usage:**
```bash
./monitor-template.sh <REPO_OWNER> <REPO_NAME> <RUNNER_NAME> [SCRIPT_DIR] [LOG_FILE]
```

**Log file:** Default `${SCRIPT_DIR}/monitor.log`

## Integration Patterns

### Pattern A: Hardcoded Copies (Current)
Each runner repo copies these scripts and hardcodes values:
- **Location:** `{runner-repo}/scripts/setup-service.sh`, `health-check.sh`, etc.
- **Advantage:** Self-contained, no external dependencies
- **Disadvantage:** Duplicated code, harder to fix bugs centrally

**Example:**
```bash
# modulo-squares-actions-runner/scripts/setup-service.sh
REPO_OWNER="mnelson3"
REPO_NAME="modulo-squares"
RUNNER_NAME="modulo-squares-macos-runner"
# ... rest of setup-service-template.sh logic
```

### Pattern B: Git Submodule (Recommended Future)
Link this directory as a git submodule in each runner repo, then create thin wrapper scripts that call the templates with appropriate parameters.

**Setup:**
```bash
cd {runner-repo}
git submodule add https://github.com/mnelson3/nelson-grey.git nelson-grey
cd scripts
ln -s ../nelson-grey/shared/runner-scripts/setup-service-template.sh setup-service
```

**Wrapper script:** `scripts/setup-service`
```bash
#!/bin/bash
../nelson-grey/shared/runner-scripts/setup-service-template.sh mnelson3 modulo-squares modulo-squares-macos-runner
```

**Advantage:** Single source of truth, centralized bug fixes, easy to push updates to all runners

### Pattern C: Direct Invocation (For CI/CD Setup)
In setup workflows or container images, directly invoke the template scripts with parameters:

```bash
/path/to/nelson-grey/shared/runner-scripts/setup-service-template.sh mnelson3 modulo-squares modulo-squares-macos-runner
```

## LaunchDaemon / Cron Integration

### LaunchDaemon for Persistent Service
The `setup-service-template.sh` creates:
```
/Library/LaunchDaemons/actions.runner.{REPO_OWNER}-{REPO_NAME}.{RUNNER_NAME}.plist
```

with `RunAtLoad: true` and `KeepAlive: true` for automatic startup and restart.

### Cron for Periodic Monitoring
To install periodic health checks, add to crontab:
```bash
*/5 * * * * /path/to/scripts/monitor.sh >> /tmp/runner-monitor.log 2>&1
```

Or use launchd (preferred on macOS):
```
/Library/LaunchAgents/com.runner.monitor.plist
```

## Security Considerations

1. **Token Management:**
   - Tokens are ephemeral (retrieved fresh via GitHub CLI or GitHub App)
   - Never committed to version control
   - Cleaned up after runner configuration

2. **Permissions:**
   - `setup-service.sh` requires `sudo` (LaunchDaemon installation)
   - Health check and auto-recover should run as the runner user (non-root)
   - Consider using `sudo` with NOPASSWD for automation

3. **Logging:**
   - Monitor logs stored in `scripts/monitor.log` (runner repo)
   - Logs contain minimal sensitive info (no tokens)
   - Log rotation recommended for long-running monitors

## Status

| Runner Repo | Pattern | Status |
|-------------|---------|--------|
| modulo-squares-actions-runner | A (Hardcoded) | ✅ Complete |
| vehicle-vitals-actions-runner | A (Hardcoded) | ✅ Complete |
| wishlist-wizard-actions-runner | A (Hardcoded) | ✅ Complete |

**Next Step:** Migrate all repos to Pattern B (submodule) or C (direct invocation) for centralized maintenance.

## Testing

To test the templates locally:

```bash
# Test health check
./health-check-template.sh mnelson3 modulo-squares modulo-squares-macos-runner

# Test auto-recover (will re-register)
./auto-recover-template.sh mnelson3 modulo-squares modulo-squares-macos-runner

# Test monitor
./monitor-template.sh mnelson3 modulo-squares modulo-squares-macos-runner
```

## Troubleshooting

**Service not loading:**
```bash
sudo launchctl load /Library/LaunchDaemons/actions.runner.*.plist
sudo launchctl list | grep actions.runner
```

**Runner offline after recovery:**
- Check GitHub token permissions
- Verify GitHub CLI is authenticated: `gh auth status`
- Check logs: `tail -f scripts/monitor.log`

**Process running but service reports unloaded:**
```bash
pkill -9 -f "runner-name"
sleep 3
sudo launchctl load /Library/LaunchDaemons/actions.runner.*.plist
```
