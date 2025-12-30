Runner Manager (prototype)
==========================

Purpose
-------
Lightweight service to create GitHub Actions self-hosted runner registration tokens using a GitHub App. Intended to run in `nelson-grey` as the central manager that runner hosts call to obtain ephemeral registration tokens.

Features
--------
- Requests installation tokens and registration tokens for a specific repo using a GitHub App.
- Optional Vault integration: fetch GitHub App private key from Vault at startup using `secure/vault/vault_fetch.sh`.
- Simple API key protection via `RUNNER_MANAGER_API_KEY` env var.

Quickstart
----------
1. Install dependencies:

   cd nelson-grey/runner-manager
   npm install

2. Provide environment variables (example):

   export GITHUB_APP_ID=12345
   export GITHUB_APP_PRIVATE_KEY_PATH=/path/to/private-key.pem
   export RUNNER_MANAGER_API_KEY="your-secret"
   export PORT=3001

3. (Optional) Use Vault: ensure `VAULT_ADDR` and `VAULT_TOKEN` are set and the private key is stored under `secret/nelson-grey/github_app_private_key`.
   The included `start.sh` will fetch the key using the vault helper.

4. Start the service:

   ./start.sh

API
---
POST /register-runner
Headers: `X-API-KEY: <RUNNER_MANAGER_API_KEY>`
Body (json): { "owner": "org-or-user", "repo": "repo-name" }

Response: { "token": "<registration-token>", "expires_at": "<timestamp>" }

Security
--------
- Use Vault and limited policies for the GitHub App private key.
- Restrict access to the `register-runner` endpoint via network controls and short-lived API keys or mutual TLS in production.
