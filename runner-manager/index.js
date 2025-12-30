#!/usr/bin/env node
try { require('dotenv').config(); } catch (_) { /* optional in dev without node deps */ }
const fs = require('fs');
const express = require('express');
// Load local .env if present (optional dependency)
try {
  require('dotenv').config({ path: require('path').join(__dirname, '.env') });
} catch (e) {
  // dotenv not installed; environment variables will be read from process.env
}
const bodyParser = require('body-parser');

// Defer requiring Octokit modules until needed so dev/testing without npm install works
let createAppAuth = null;
let Octokit = null;

const APP_ID = process.env.GITHUB_APP_ID;
const PRIVATE_KEY_PATH = process.env.GITHUB_APP_PRIVATE_KEY_PATH;
const PORT = process.env.PORT || 3001;

// API keys: either RUNNER_MANAGER_API_KEYS (comma-separated) or RUNNER_MANAGER_API_KEYS_FILE path
const apiKeysEnv = process.env.RUNNER_MANAGER_API_KEYS || process.env.RUNNER_MANAGER_API_KEY || '';
let ALLOWED_API_KEYS = [];
if (apiKeysEnv) {
  ALLOWED_API_KEYS = apiKeysEnv.split(',').map(s => s.trim()).filter(Boolean);
} else if (process.env.RUNNER_MANAGER_API_KEYS_FILE) {
  try {
    const data = fs.readFileSync(process.env.RUNNER_MANAGER_API_KEYS_FILE, 'utf8');
    ALLOWED_API_KEYS = data.split(/\r?\n/).map(s => s.trim()).filter(Boolean);
  } catch (e) {
    console.error('Failed to read RUNNER_MANAGER_API_KEYS_FILE:', e.message);
  }
}

// Basic rate limiter (in-memory): per-repo windowed counter
const RATE_WINDOW = parseInt(process.env.RATE_LIMIT_WINDOW_SECONDS || '60', 10);
const RATE_MAX = parseInt(process.env.RATE_LIMIT_MAX || '30', 10);
const counters = new Map(); // key -> {count, windowStart}

function now() { return Date.now(); }

function log(...args) { console.log(new Date().toISOString(), ...args); }

if (!APP_ID && process.env.DEV_FAKE_TOKENS !== '1') {
  console.error('GITHUB_APP_ID is required');
  process.exit(2);
}

let privateKey = process.env.GITHUB_APP_PRIVATE_KEY || '';
if (!privateKey && process.env.DEV_FAKE_TOKENS !== '1') {
  if (!PRIVATE_KEY_PATH || !fs.existsSync(PRIVATE_KEY_PATH)) {
    console.error('GITHUB_APP_PRIVATE_KEY_PATH or GITHUB_APP_PRIVATE_KEY must be set');
    process.exit(2);
  }
  privateKey = fs.readFileSync(PRIVATE_KEY_PATH, 'utf8');
}

const app = express();
// preserve raw body for webhook signature verification
app.use(bodyParser.json({ verify: function (req, res, buf) { req.rawBody = buf; } }));

const https = require('https');
const crypto = require('crypto');

function base64UrlEncode(buf) {
  return buf.toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

function createAppJWT(appId, pemPrivateKey) {
  const header = base64UrlEncode(Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })));
  const iat = Math.floor(Date.now() / 1000);
  const exp = iat + (10 * 60); // 10 minutes
  const payload = base64UrlEncode(Buffer.from(JSON.stringify({ iat, exp, iss: String(appId) })));
  const toSign = `${header}.${payload}`;
  const sign = crypto.createSign('RSA-SHA256');
  sign.update(toSign);
  sign.end();
  const signature = sign.sign(pemPrivateKey);
  const sigb64 = base64UrlEncode(Buffer.from(signature));
  return `${toSign}.${sigb64}`;
}

function githubApiRequest(method, path, token, body) {
  const opts = {
    hostname: 'api.github.com',
    port: 443,
    path,
    method,
    headers: {
      'User-Agent': 'nelson-grey-runner-manager/1.0',
      'Accept': 'application/vnd.github+json',
    }
  };
  if (token) opts.headers['Authorization'] = token;
  if (body) {
    const s = JSON.stringify(body);
    opts.headers['Content-Type'] = 'application/json';
    opts.headers['Content-Length'] = Buffer.byteLength(s);
  }

  return new Promise((resolve, reject) => {
    const req = https.request(opts, (res) => {
      let data = '';
      res.setEncoding('utf8');
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data || '{}');
          if (res.statusCode && res.statusCode >= 400) return reject(new Error(`GitHub API ${res.statusCode}: ${data}`));
          resolve(parsed);
        } catch (err) {
          reject(err);
        }
      });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

function requireApiKey(req, res, next) {
  if (process.env.DEV_ALLOW_ANON === '1') return next();
  if (!ALLOWED_API_KEYS || ALLOWED_API_KEYS.length === 0) return res.status(403).json({ error: 'API key(s) not configured' });
  const key = req.headers['x-api-key'];
  if (!key || !ALLOWED_API_KEYS.includes(key)) return res.status(401).json({ error: 'invalid api key' });
  next();
}

function enforceHttps(req, res, next) {
  if (process.env.REQUIRE_HTTPS === '1') {
    const proto = req.headers['x-forwarded-proto'] || (req.connection && req.connection.encrypted ? 'https' : 'http');
    if (proto !== 'https' && !req.secure) {
      return res.status(426).json({ error: 'https required' });
    }
  }
  next();
}

function rateLimitForRepo(owner, repo) {
  const key = `${owner}/${repo}`;
  const entry = counters.get(key) || { count: 0, windowStart: now() };
  if (now() - entry.windowStart > RATE_WINDOW * 1000) {
    entry.count = 0;
    entry.windowStart = now();
  }
  entry.count += 1;
  counters.set(key, entry);
  return entry.count <= RATE_MAX;
}

app.post('/register-runner', enforceHttps, requireApiKey, async (req, res) => {
  try {
    // Development helper: return a fake token without calling GitHub when enabled
    if (process.env.DEV_FAKE_TOKENS === '1') {
      const fake = {
        token: `dev-token-${Math.random().toString(36).slice(2,10)}`,
        expires_at: new Date(Date.now() + 1000 * 60 * 60).toISOString()
      };
      log('DEV_FAKE_TOKENS active; issuing fake token');
      return res.json(fake);
    }

    const { owner, repo } = req.body || {};
    if (!owner || !repo) return res.status(400).json({ error: 'owner and repo required' });

    // rate limit per repo
    if (!rateLimitForRepo(owner, repo)) {
      log('rate limited', owner, repo);
      return res.status(429).json({ error: 'rate limit exceeded' });
    }

    // Lazy-require Octokit modules so service can run in dev without npm install
    let haveOctokit = true;
    try {
      if (!createAppAuth) {
        const mod = require('@octokit/auth-app');
        createAppAuth = mod.createAppAuth || mod;
      }
      if (!Octokit) {
        Octokit = require('@octokit/rest').Octokit;
      }
    } catch (e) {
      haveOctokit = false;
      log('Octokit not available, will attempt raw HTTP fallback:', e.message);
    }

    // Read private key
    let privateKey = process.env.GITHUB_APP_PRIVATE_KEY || '';
    if (!privateKey) {
      if (!PRIVATE_KEY_PATH || !fs.existsSync(PRIVATE_KEY_PATH)) {
        log('GitHub private key not configured');
        return res.status(500).json({ error: 'GITHUB_APP_PRIVATE_KEY_PATH or GITHUB_APP_PRIVATE_KEY must be set' });
      }
      privateKey = fs.readFileSync(PRIVATE_KEY_PATH, 'utf8');
    }

    if (!APP_ID) {
      log('GITHUB_APP_ID not configured');
      return res.status(500).json({ error: 'GITHUB_APP_ID must be set' });
    }

    // If Octokit is available use it, otherwise fall back to raw HTTP JWT flow
    if (haveOctokit) {
      // Authenticate as the App (app token)
      const appAuth = createAppAuth({ appId: APP_ID, privateKey });
      const appAuthentication = await appAuth({ type: 'app' });
      const appToken = appAuthentication.token;

      const octokitApp = new Octokit({ auth: appToken });

      // Get installation id for repo
      const installResp = await octokitApp.request('GET /repos/{owner}/{repo}/installation', { owner, repo });
      const installationId = installResp.data.id;

      // Create installation auth (token)
      const installationAuth = await appAuth({ type: 'installation', installationId });
      const installationToken = installationAuth.token;

      // Use installation token to request registration token
      const octokitInst = new Octokit({ auth: installationToken });
      const reg = await octokitInst.request('POST /repos/{owner}/{repo}/actions/runners/registration-token', { owner, repo });

      log('issued token for', owner, repo);
      return res.json({ token: reg.data.token, expires_at: reg.data.expires_at });
    } else {
      // Raw HTTP fallback using JWT signed with private key
      try {
        const jwt = createAppJWT(APP_ID, privateKey);
        // get installation
        const inst = await githubApiRequest('GET', `/repos/${owner}/${repo}/installation`, `Bearer ${jwt}`);
        const installationId = inst.id || inst.data && inst.data.id;
        if (!installationId) throw new Error('installation id not found');
        // create installation token
        const instTokenResp = await githubApiRequest('POST', `/app/installations/${installationId}/access_tokens`, `Bearer ${jwt}`);
        const installationToken = instTokenResp.token || instTokenResp.data && instTokenResp.data.token;
        if (!installationToken) throw new Error('installation token not received');
        // request registration token
        const regResp = await githubApiRequest('POST', `/repos/${owner}/${repo}/actions/runners/registration-token`, `token ${installationToken}`);
        const token = regResp.token || regResp.data && regResp.data.token;
        const expires_at = regResp.expires_at || (regResp.data && regResp.data.expires_at);
        log('issued token for', owner, repo, '(raw-http)');
        return res.json({ token, expires_at });
      } catch (e) {
        log('raw http fallback failed', e && e.message);
        return res.status(500).json({ error: 'raw HTTP GitHub flow failed: ' + (e && e.message) });
      }
    }
  } catch (err) {
    log('error in /register-runner', err && err.message);
    return res.status(500).json({ error: err.message || String(err) });
  }
});

// GitHub webhook endpoint
function verifyGithubSignature(req) {
  const secret = process.env.RUNNER_MANAGER_WEBHOOK_SECRET || '';
  if (!secret) return { ok: false, error: 'no webhook secret configured' };
  const sig = req.headers['x-hub-signature-256'] || '';
  if (!sig || typeof sig !== 'string') return { ok: false, error: 'missing signature' };
  const expectedPrefix = 'sha256=';
  if (!sig.startsWith(expectedPrefix)) return { ok: false, error: 'invalid signature format' };
  const sigHex = sig.slice(expectedPrefix.length);
  const hmac = require('crypto').createHmac('sha256', secret).update(req.rawBody || Buffer.from('')).digest('hex');
  // timing-safe compare
  const safeEqual = require('crypto').timingSafeEqual(Buffer.from(hmac, 'hex'), Buffer.from(sigHex, 'hex'));
  return { ok: Boolean(safeEqual), expected: hmac, received: sigHex };
}

app.post('/github-webhook', express.raw({ type: '*/*' }), (req, res) => {
  // express.raw used to populate req.body as Buffer here; ensure rawBody exists
  if (!req.rawBody && req.body) req.rawBody = Buffer.isBuffer(req.body) ? req.body : Buffer.from(JSON.stringify(req.body));
  const check = verifyGithubSignature(req);
  if (!check.ok) {
    log('webhook signature verification failed:', check.error || check);
    return res.status(401).json({ error: 'invalid signature' });
  }

  const event = req.headers['x-github-event'] || 'unknown';
  const delivery = req.headers['x-github-delivery'] || '';
  let payload = {};
  try { payload = JSON.parse(req.rawBody.toString('utf8') || '{}'); } catch (e) { payload = {}; }

  log('webhook received', { event, delivery, repo: payload.repository && payload.repository.full_name });

  // Minimal handling: installation events can be used to pre-warm tokens or log
  if (event === 'installation') {
    log('installation event action=', payload.action);
  } else if (event === 'installation_repositories') {
    log('installation_repositories action=', payload.action);
  }

  // Return 200 quickly; background tasks could be queued here
  res.json({ status: 'ok' });
});

app.listen(PORT, () => {
  console.log(`Runner Manager listening on port ${PORT}`);
});
