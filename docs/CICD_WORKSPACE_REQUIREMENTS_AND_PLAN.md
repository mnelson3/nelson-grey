# CI/CD Workspace Requirements & Plan

This workspace contains multiple application repos and their corresponding self-hosted runner repos. The goal is a consistent **zero-touch** CI/CD posture (especially iOS distribution) with **centralized credentialing** in `nelson-grey`.

## Core requirements (workspace-wide)

### R1. Zero-touch iOS distribution
- iOS builds and distribution must run without interactive prompts.
- Apple auth uses App Store Connect API key (`APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY`).
- Code signing uses Fastlane Match via HTTPS token auth (no SSH deploy keys baked into repos).
- Signing must run inside an ephemeral keychain (no login keychain pollution).
- Workflows must clean up any generated secret artifacts (ASC key file, Fastlane `.env`, service-account json).

### R2. Centralized credentialing
- Signing assets (Match repo) are stored in `nelson-grey` and referenced by all apps.
- Rotation orchestration is centralized in `nelson-grey` (e.g. `.github/workflows/ci-rotate.yml`).
- No long-lived credentials are committed anywhere (history rewrites already completed where needed).

### R3. Runner reliability (self-healing)
- Self-hosted runners must survive:
  - host reboot,
  - runner process crash,
  - loss of connectivity or broken runner registration.
- Minimum behavior:
  - `KeepAlive` for the runner service,
  - a watchdog that periodically checks health and restarts/re-registers when needed.

### R4. Docker runner reliability (if used)
- If a repo uses docker-based self-hosted runners (`*-docker-runner`), a periodic health check must:
  - ensure docker is running,
  - ensure the runner container exists and is running,
  - restart the container when missing/offline.

### R5. Auditability and documentation
- Every repo has a short workstream plan documenting:
  - required secrets,
  - runner labels,
  - how releases are triggered,
  - what “done” means.

## Workstreams and status

### WS-A: iOS distribution standardization (DONE)
- Standardized to: ASC API key auth + Match over HTTPS + ephemeral keychain.
- Implemented across: `modulo-squares`, `vehicle-vitals`, `wishlist-wizard`.

### WS-B: Runner reliability / auto-recovery (✅ DONE)
- Add/align runner watchdogs (LaunchDaemon preferred for true zero-touch).
- **Status:** All three runner repos now have complete watchdog implementations
  - `modulo-squares-actions-runner`: ✅ setup-service.sh, health-check.sh, auto-recover.sh, monitor.sh
  - `vehicle-vitals-actions-runner`: ✅ setup-service.sh, health-check.sh, auto-recover.sh, monitor.sh
  - `wishlist-wizard-actions-runner`: ✅ (already complete)
- Shared templates created in `nelson-grey/shared/runner-scripts/` for future centralization

### WS-C: Docker runners auto-restart (IN PROGRESS)
- Token refresh + health checks run on a schedule and now attempt a container restart when unhealthy.
- Next: confirm these health checks are installed/loaded on the runner hosts.

### WS-D: Key rotation follow-up (OPEN)
- Rotate/revoke historically-committed Firebase service account keys.
- Validate CI after rotation.

## Repo-level plans
- `modulo-squares`: see [modulo-squares/docs/CICD_WORKSTREAMS.md](../../modulo-squares/docs/CICD_WORKSTREAMS.md)
- `vehicle-vitals`: see [vehicle-vitals/docs/CICD_WORKSTREAMS.md](../../vehicle-vitals/docs/CICD_WORKSTREAMS.md)
- `wishlist-wizard`: see [wishlist-wizard/docs/CICD_WORKSTREAMS.md](../../wishlist-wizard/docs/CICD_WORKSTREAMS.md)

Runner repos:
- `modulo-squares-actions-runner`: see [modulo-squares-actions-runner/RUNNER_WORKSTREAMS.md](../../modulo-squares-actions-runner/RUNNER_WORKSTREAMS.md)
- `vehicle-vitals-actions-runner`: see [vehicle-vitals-actions-runner/RUNNER_WORKSTREAMS.md](../../vehicle-vitals-actions-runner/RUNNER_WORKSTREAMS.md)
- `wishlist-wizard-actions-runner`: see [wishlist-wizard-actions-runner/RUNNER_WORKSTREAMS.md](../../wishlist-wizard-actions-runner/RUNNER_WORKSTREAMS.md)
