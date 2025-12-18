**Create & Install the GitHub App for Runner Manager**

This guide helps you create a GitHub App that the `runner-manager` will use to mint installation tokens and receive webhook events.

1) Use the manifest (optional)

- A sample manifest is provided at `github-app-manifest.json`. You can use it as a reference when creating the App in the GitHub UI, or copy fields into the web form.

2) Create the App via GitHub UI

- In GitHub: Settings → Developer settings → GitHub Apps → New GitHub App
- Fill fields:
  - **App name**: Nelson Runner Manager
  - **Homepage URL**: set to `https://nelson-grey.example.org/runner-manager`
  - **Webhook URL**: `https://amy-propretorian-evalyn.ngrok-free.dev/github-webhook`
  - **Webhook secret**: choose a strong secret and set it as `RUNNER_MANAGER_WEBHOOK_SECRET` in the manager env
  - **Permissions** (important): set `Actions` to `Read & write`, set `Metadata` to `Read`
  - **Subscribe to events**: check `installation` and `installation_repositories`
- Create the app.

3) Install the App into repositories

- After creation, click **Install App** and choose the organization or repositories the runner-manager should manage. Installing gives the App an installation ID scoped to that target.

4) Download the private key and record the App ID

- In the App's Settings page, generate and download the private key (a `.pem` file). Save it securely on the manager host, e.g. `/etc/nelson-grey/runner-manager/app-private-key.pem` and restrict filesystem permissions.
- Note the **App ID** (number) from the App page.

5) Wire into `runner-manager`

- Set environment variables for the manager process (example):

```
RUNNER_MANAGER_API_KEYS=GJ2pObDz/mWEGCauiwtdg96HaojjHAEdSecxqcjXACE=
RUNNER_MANAGER_WEBHOOK_SECRET=841d31f74d2c7ac6377835279c5471ed68ff79d0e594291f4594c7c74e6f278c
GITHUB_APP_ID=2484158
GITHUB_APP_PRIVATE_KEY_PATH=/etc/nelson-grey/runner-manager/app-private-key.pem
PORT=3001
node index.js
```

6) Restart service and verify

- Restart the manager and verify logs show it can create an installation access token. Then test:

```
curl -H "X-API-KEY: testkey" -H "Content-Type: application/json" -d '{"owner":"org-or-user","repo":"repo-name"}' http://127.0.0.1:3001/register-runner
```

7) Webhook tip

- Configure the GitHub App webhook to point to your public URL (ngrok or a real TLS endpoint). Set the same webhook secret you exported to `RUNNER_MANAGER_WEBHOOK_SECRET` so the manager can validate signatures.

Security notes
- Keep the private key out of git and restrict its filesystem permissions.
- Rotate `RUNNER_MANAGER_API_KEYS` periodically and use multiple keys (comma-separated) if needed.
