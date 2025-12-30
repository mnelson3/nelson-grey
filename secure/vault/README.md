Vault prototype for nelson-grey
==============================

This folder contains simple helper scripts to prototype storing and fetching secrets from HashiCorp Vault.

Prerequisites
-------------
- `vault` CLI installed and configured to talk to a Vault server (dev server ok for prototype).
- An auth method configured for your environment (token, AppRole, etc.).

Files
-----
- `vault_store.sh` — store a secret (e.g., App Store Connect `.p8`, match passphrase).
- `vault_fetch.sh` — fetch a secret and write to disk (used by CI/runners before running Fastlane).
- `policy_match.hcl` — example Vault policy granting read access to match secrets.

Usage examples
--------------
Store a secret:

  ./vault_store.sh asc_private_key /path/to/AuthKey.p8

Fetch a secret:

  ./vault_fetch.sh asc_private_key /tmp/AuthKey.p8

The scripts are intentionally minimal — for production, integrate with AppRole/Kubernetes auth and secure the Vault policies.
