Runner registration helper
==========================

This folder includes `register_runner.sh` — a small helper for self-hosted runners to request
a short-lived registration token from the `runner-manager` service and optionally run the
Actions runner `config.sh` to perform registration.

Quick start
-----------

1. Ensure `runner-manager` is reachable and you have an API key:

   - `RUNNER_MANAGER_URL` e.g. `https://runners.example.com`
   - `RUNNER_MANAGER_API_KEY` (set in environment)

2. From the runner host, run:

```bash
RUNNER_MANAGER_URL=https://runners.example.com \
  RUNNER_MANAGER_API_KEY=REDACTED \
  ./register_runner.sh --owner my-org --repo my-repo --runner-dir /opt/actions-runner --auto
```

Notes
-----

- The script expects the `runner-manager` endpoint `POST /register-runner` to accept JSON
  `{ "owner": "<owner>", "repo": "<repo>" }` and return JSON `{ "token": "...", "expires_at": "..." }`.
- The `--auto` flag will attempt to call the runner's `config.sh` (requires that script to be present
  and executable in `--runner-dir`). The helper will use `sudo` to run the config script to ensure
  it can create service entries; adjust per your runner setup.
- If `jq` is not installed, the script falls back to a small Python JSON parser.

Security
--------

- Keep `RUNNER_MANAGER_API_KEY` secret and rotate it regularly.
- Host the `runner-manager` behind TLS and restrict access by IP where possible.
