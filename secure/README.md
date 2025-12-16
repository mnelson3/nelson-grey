# Fastlane CI rotation (secure)

This folder contains Fastlane lanes and CI helpers to rotate iOS signing certificates and provisioning profiles using `match`.

Purpose
- Provide a zero-touch scheduled job that runs `fastlane match` for configured projects and pushes any generated certificates/profiles into a secure `match` repo.

How it works
- A GitHub Actions workflow in the repository runs `secure/fastlane/ci_rotate.sh` on a self-hosted macOS runner.
- `ci_rotate.sh` reads `ROTATE_PROJECTS` (comma-separated list) and for each project it looks for per-project secrets first, then falls back to global secrets.

Required secrets (per-project or global)
- Global names (fallbacks):
  - `MATCH_GIT_URL` — git URL for the match repo (SSH or HTTPS)
  - `MATCH_PASSWORD` — match passphrase
  - `MATCH_GIT_URL_TOKEN` — optional PAT if using HTTPS access
  - `ASC_PRIVATE_KEY` — base64-encoded App Store Connect private key (.p8)
  - `ASC_ISSUER_ID` — App Store Connect issuer ID
  - `ASC_KEY_ID` — App Store Connect key ID
  - `FASTLANE_APPLE_ID` — Apple ID/email for match `username`

- Per-project names (suffix pattern):
  - `MATCH_GIT_URL_<PROJECT>`
  - `MATCH_PASSWORD_<PROJECT>`
  - `MATCH_GIT_URL_TOKEN_<PROJECT>`
  - `ASC_PRIVATE_KEY_<PROJECT>`
  - `ASC_ISSUER_ID_<PROJECT>`
  - `ASC_KEY_ID_<PROJECT>`
  - `FASTLANE_APPLE_ID_<PROJECT>`

  Where `<PROJECT>` is the uppercase project name with dashes replaced by underscores.
  Examples:
  - Project `vehicle-vitals` -> suffix `_VEHICLE_VITALS`
  - Project `modulo-squares` -> suffix `_MODULO_SQUARES`

Security notes
- Prefer storing `ASC_PRIVATE_KEY` and other secrets in GitHub Secrets or a Vault and not in plaintext files.
- `ASC_PRIVATE_KEY` value should be the base64 encoding of the `.p8` PEM contents. The CI script will decode it into `secure/asc_key.p8` with `0600` permissions before invoking Fastlane.
- After any secret rotation, purge old keys from git history using the repository's `scripts/remove_key_history.sh` helper (or `git-filter-repo`).

CI setup checklist
1. Register a self-hosted macOS runner with labels `self-hosted` and `macOS` (or adjust `runs-on`).
2. Add the required secrets (global or per-project) in the repository `Settings → Secrets`.
3. Verify the match repo is reachable from the runner (SSH deploy key or PAT).
4. Optionally, adjust the `cron` schedule in `.github/workflows/ci-rotate.yml`.

Troubleshooting
- If `fastlane` reports App Store Connect auth errors, confirm `ASC_ISSUER_ID`, `ASC_KEY_ID`, and `ASC_PRIVATE_KEY` match an active App Store Connect API key.
- If `match` cannot push to the match repo, ensure the runner has SSH keys or the PAT has repo access.
nelson-grey secure store & Fastlane prototype
===========================================

Purpose
-------
This folder is a starter prototype for centralizing iOS signing artifacts and automating rotation with Fastlane `match`.

What is included
-----------------
- `Gemfile` — pins `fastlane` for local runs via `bundle`.
- `fastlane/Matchfile` — `match` configuration (git backend placeholder).
- `fastlane/Fastfile` — lanes to fetch/create certs and provisioning profiles.
- `setup_match.sh` — helper to create a local encrypted match repo (for prototype).
- `run_match.sh` — wrapper to run fastlane lanes using an App Store Connect API key.
- `match_repo/` — placeholder for an encrypted match repo (do NOT commit secrets here).

Security notes
--------------
- Do NOT commit private keys, `.p12`, `.p8`, or mobileprovision files into git.
- Use the platform of your choice for secure storage (Vault, S3+KMS, or an encrypted Git repo).
- This prototype uses an encrypted Git match repo as an example. For production, prefer a hardened secret manager.

Quickstart (macOS / local)
--------------------------
1. Install Ruby Bundler and gems in this folder:

   bundle install

2. Create App Store Connect API key and make it available as JSON at `ASC_KEY.json` or via `ENV`.

3. Initialize the match repo (prototype):

   ./setup_match.sh

4. Run a fastlane lane to fetch development certs (will prompt for passphrase to encrypt match files):

   ./run_match.sh development

Next steps
----------
- Replace the placeholder `git_url` in `fastlane/Matchfile` to a remote encrypted Git repo or configure S3.
- Integrate secrets access: store App Store Connect `.p8` and match repo credentials in `nelson-grey`'s secure store (Vault or cloud secret manager).

Vault integration (prototype)
-----------------------------
Optionally, you can use HashiCorp Vault as the central secret store. This repository includes a small prototype under `secure/vault/` with helper scripts to store and fetch secrets.

High-level flow:
- Store the App Store Connect `.p8` and the `match` repo encryption passphrase in Vault.
- Update `run_match.sh` or CI runner startup to fetch required secrets from Vault before running `fastlane match`.

Security note: For production, run a Vault cluster (HA) and restrict access using Vault policies and AppRole or Kubernetes auth. The prototype uses CLI-auth for simplicity.

Do not commit actual secrets into this repository.
