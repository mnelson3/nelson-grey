#!/usr/bin/env node
// Minimal runner-manager using only Node built-ins for environments without npm
const http = require('http');
const https = require('https');
const fs = require('fs');
const crypto = require('crypto');

const PORT = process.env.PORT || 3001;
const APP_ID = process.env.GITHUB_APP_ID;
const PRIVATE_KEY_PATH = process.env.GITHUB_APP_PRIVATE_KEY_PATH;
const apiKeysEnv = process.env.RUNNER_MANAGER_API_KEYS || process.env.RUNNER_MANAGER_API_KEY || '';
let ALLOWED_API_KEYS = [];
if (apiKeysEnv) ALLOWED_API_KEYS = apiKeysEnv.split(',').map(s => s.trim()).filter(Boolean);
else if (process.env.RUNNER_MANAGER_API_KEYS_FILE) {
  try { ALLOWED_API_KEYS = fs.readFileSync(process.env.RUNNER_MANAGER_API_KEYS_FILE,'utf8').split(/\r?\n/).map(s=>s.trim()).filter(Boolean); } catch(e){}
}

const RATE_WINDOW = parseInt(process.env.RATE_LIMIT_WINDOW_SECONDS || '60',10);
const RATE_MAX = parseInt(process.env.RATE_LIMIT_MAX || '30',10);
const counters = new Map();
function now(){return Date.now();}
function base64UrlEncode(buf){return buf.toString('base64').replace(/=/g,'').replace(/\+/g,'-').replace(/\//g,'_');}
function createAppJWT(appId, pemPrivateKey){
  const header = base64UrlEncode(Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })));
  const iat = Math.floor(Date.now()/1000);
  const exp = iat + (10*60);
  const payload = base64UrlEncode(Buffer.from(JSON.stringify({ iat, exp, iss: String(appId) })));
  const toSign = `${header}.${payload}`;
  const sign = crypto.createSign('RSA-SHA256');
  sign.update(toSign); sign.end();
  const signature = sign.sign(pemPrivateKey);
  const sigb64 = base64UrlEncode(Buffer.from(signature));
  return `${toSign}.${sigb64}`;
}
function githubApiRequest(method, path, token, body){
  const opts = { hostname: 'api.github.com', port: 443, path, method, headers: { 'User-Agent':'nelson-grey-runner-manager/1.0','Accept':'application/vnd.github+json' } };
  if (token) opts.headers['Authorization']=token;
  return new Promise((resolve,reject)=>{
    const req = https.request(opts,(res)=>{let data='';res.setEncoding('utf8');res.on('data',c=>data+=c);res.on('end',()=>{try{const parsed=JSON.parse(data||'{}'); if(res.statusCode>=400) return reject(new Error(`GitHub API ${res.statusCode}: ${data}`)); resolve(parsed);}catch(e){reject(e);}});});
    req.on('error',reject);
    if (body){ const s=JSON.stringify(body); req.setHeader && req.setHeader('Content-Type','application/json'); req.write(s);} req.end();
  });
}

function rateLimitForRepo(owner,repo){ const key=`${owner}/${repo}`; const entry=counters.get(key)||{count:0,windowStart:now()}; if(now()-entry.windowStart>RATE_WINDOW*1000){entry.count=0;entry.windowStart=now();} entry.count+=1; counters.set(key,entry); return entry.count<=RATE_MAX; }

function sendJSON(res,obj,code=200){ const s=JSON.stringify(obj); res.writeHead(code,{'Content-Type':'application/json'}); res.end(s); }

const server = http.createServer(async (req,res)=>{
  try{
    const url = new URL(req.url, `http://${req.headers.host}`);
    if (url.pathname === '/healthz') return sendJSON(res,{status:'ok'});
    if (url.pathname === '/metrics') return sendJSON(res,{uptime:process.uptime(),now:new Date().toISOString()});
    if (req.method === 'POST' && url.pathname === '/register-runner'){
      let body=''; req.on('data',c=>body+=c); await new Promise(r=>req.on('end',r));
      const apiKey = req.headers['x-api-key'] || '';
      if (!(process.env.DEV_ALLOW_ANON==='1') && ALLOWED_API_KEYS.length>0 && !ALLOWED_API_KEYS.includes(apiKey)) return sendJSON(res,{error:'invalid api key'},401);
      const data = body ? JSON.parse(body) : {};
      const owner = data.owner; const repo = data.repo; if(!owner||!repo) return sendJSON(res,{error:'owner and repo required'},400);
      if (process.env.DEV_FAKE_TOKENS==='1') return sendJSON(res,{token:`dev-token-${Math.random().toString(36).slice(2,10)}`,expires_at:new Date(Date.now()+3600000).toISOString()});
      if(!rateLimitForRepo(owner,repo)) return sendJSON(res,{error:'rate limit exceeded'},429);
      // require app id and private key
      const appId = process.env.GITHUB_APP_ID || APP_ID;
      let pem = process.env.GITHUB_APP_PRIVATE_KEY || '';
      if(!pem){ if(!PRIVATE_KEY_PATH || !fs.existsSync(PRIVATE_KEY_PATH)) return sendJSON(res,{error:'private key not configured'},500); pem = fs.readFileSync(PRIVATE_KEY_PATH,'utf8'); }
      try{
        const jwt = createAppJWT(appId,pem);
        const inst = await githubApiRequest('GET',`/repos/${owner}/${repo}/installation`, `Bearer ${jwt}`);
        const installationId = inst.id || (inst.data && inst.data.id);
        if(!installationId) throw new Error('installation id not found');
        const instTokenResp = await githubApiRequest('POST',`/app/installations/${installationId}/access_tokens`, `Bearer ${jwt}`);
        const installationToken = instTokenResp.token || (instTokenResp.data && instTokenResp.data.token);
        if(!installationToken) throw new Error('installation token missing');
        const regResp = await githubApiRequest('POST',`/repos/${owner}/${repo}/actions/runners/registration-token`, `token ${installationToken}`);
        const token = regResp.token || (regResp.data && regResp.data.token);
        const expires_at = regResp.expires_at || (regResp.data && regResp.data.expires_at);
        return sendJSON(res,{token,expires_at});
      }catch(e){ return sendJSON(res,{error: e && e.message || String(e)},500); }
    }
    sendJSON(res,{error:'not found'},404);
  }catch(e){ sendJSON(res,{error:e.message||String(e)},500); }
});

server.listen(PORT, '127.0.0.1', ()=>{ console.log(`Minimal runner-manager listening on http://127.0.0.1:${PORT}`); });
