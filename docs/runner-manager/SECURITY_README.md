**Runner Manager — Security Notes**

Summary
-------
- Do NOT commit private keys or plaintext secrets into git. If they were committed, rotate them immediately.
- `.env` and key files should be ignored via `.gitignore`; we added those entries.

Removing leaked secrets
----------------------
- Prefer `git-filter-repo` to purge files from history. See `scripts/remove_key_history.sh` for an automated helper.
- Alternatively use the BFG Repo Cleaner (recommended workflow in its docs).
- After history rewrite: force-push the cleaned branches and inform collaborators to reclone.

In-repo secure options
----------------------
- Use SOPS (with KMS) or `git-crypt` to keep encrypted secrets committed to the repo.
- Use CI secret stores (GitHub Actions secrets, org-level secrets) to inject keys at runtime.
- Keep an `.env.example` in repo; keep real `.env` gitignored and with `chmod 600`.

Runtime
-------
- The manager now attempts to load `.env` (if `dotenv` is installed). If you prefer enforced secret fetch at startup,
  consider adding Vault integration so the process does not rely on filesystem secrets.

Rotation
--------
- After any exposure, rotate: (1) generate new GitHub App private key, (2) update manager `.env`, (3) rotate any API keys distributed to runners.
