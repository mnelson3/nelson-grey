Runner Manager Hardening Notes
==============================

This document lists recommended hardening steps and explains the runtime protections implemented in `index.js`.

Implemented protections
- API key rotation: Accepts `RUNNER_MANAGER_API_KEYS` (comma-separated) or a file via `RUNNER_MANAGER_API_KEYS_FILE`.
- TLS enforcement: set `REQUIRE_HTTPS=1` to require requests arrive over HTTPS (or behind an HTTPS terminator that sets `X-Forwarded-Proto`).
- Rate limiting: simple in-memory per-repo rate limiter controlled by `RATE_LIMIT_WINDOW_SECONDS` and `RATE_LIMIT_MAX`.
- Dev/testing shortcuts: set `DEV_FAKE_TOKENS=1` to issue fake tokens without contacting GitHub; set `DEV_ALLOW_ANON=1` to bypass API key checks in development.
- Health and metrics endpoints: `/healthz` and `/metrics` for monitoring.
- Deferred GitHub client modules: Octokit is required lazily so dev environments can run the service without installing Node deps (use `DEV_FAKE_TOKENS=1`).

Recommended production deployment steps
1. Run the service behind a TLS-terminating reverse proxy (nginx, envoy) or use `node` with TLS. Set `REQUIRE_HTTPS=1`.
2. Store API keys in a secrets manager and provide them via `RUNNER_MANAGER_API_KEYS_FILE` on disk with strict permissions (mode 600).
3. Use GitHub App authentication with a private key stored in a secure secret store, and set `GITHUB_APP_PRIVATE_KEY_PATH` to the key file path. Limit file access to the service account user.
4. Configure process supervision (systemd) and resource limits. See `runner-manager.service.sample` for a minimal unit.
5. Enable logging aggregation and alerting on `/metrics` (rate limit spikes) and `/healthz` failures.
6. Consider adding mutual TLS or IP allowlisting for additional protection.

Notes on rate limiting
- The current in-memory limiter is simple and suitable for single-instance deployments. For HA setups, use an external store (Redis) and a proven rate-limiting middleware.

Key rotation guidance
- To rotate API keys, write a new key to the keys file or update `RUNNER_MANAGER_API_KEYS` with the new comma-separated list. Restart service if keys are provided via env.
- Prefer rolling re-deploy with a new key injected into runners before revoking the old key.
