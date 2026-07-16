import https from 'node:https';

const DEFAULT_DEV_SUPABASE_URL = 'https://pywjwsrjzgkvgplkxdry.supabase.co';
const DEFAULT_DEV_SUPABASE_KEY = 'sb_publishable_Jn4aL5TQIzd6mPm5JayQeA_M7dzGBn9';

const url = String(process.env.TAINT_DEV_SUPABASE_URL || DEFAULT_DEV_SUPABASE_URL).replace(/\/+$/, '');
const key = String(process.env.TAINT_DEV_SUPABASE_KEY || process.env.TAINT_DEV_SUPABASE_PUBLISHABLE_KEY || DEFAULT_DEV_SUPABASE_KEY).trim();
const timeoutMs = Number(process.env.TAINT_DB_CHECK_TIMEOUT_MS || 12000);

if (!url || !/^https:\/\/[^/\s]+\.supabase\.co$/.test(url)) {
  throw new Error(`Invalid TAINT_DEV_SUPABASE_URL: ${url || '(empty)'}`);
}
if (!key || !(key.startsWith('sb_publishable_') || key.startsWith('eyJ'))) {
  throw new Error('TAINT_DEV_SUPABASE_KEY must be the browser-safe dev publishable or anon key.');
}

const endpoint = `${url}/rest/v1/stats?select=key&limit=1`;
const startedAt = Date.now();
const headers = {
  apikey: key,
  Accept: 'application/json'
};
if (!key.startsWith('sb_publishable_')) {
  headers.Authorization = `Bearer ${key}`;
}

try {
  const response = await requestJson(endpoint, headers, timeoutMs);
  const elapsedMs = Date.now() - startedAt;

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw new Error(`Dev Supabase REST check failed with HTTP ${response.statusCode}: ${response.body.slice(0, 220)}`);
  }

  const rows = JSON.parse(response.body);
  if (!Array.isArray(rows)) {
    throw new Error('Dev Supabase REST check returned a non-array response.');
  }

  console.log(JSON.stringify({
    ok: true,
    environment: 'dev',
    project_url: url,
    checked_endpoint: '/rest/v1/stats?select=key&limit=1',
    row_count: rows.length,
    elapsed_ms: elapsedMs,
    checked_at: new Date().toISOString()
  }, null, 2));
} catch (error) {
  const elapsedMs = Date.now() - startedAt;
  console.error(JSON.stringify({
    ok: false,
    environment: 'dev',
    project_url: url,
    checked_endpoint: '/rest/v1/stats?select=key&limit=1',
    elapsed_ms: elapsedMs,
    error: error.message,
    checked_at: new Date().toISOString()
  }, null, 2));
  process.exitCode = 1;
}

function requestJson(requestUrl, headers, timeout) {
  return new Promise((resolve, reject) => {
    const req = https.request(requestUrl, {
      method: 'GET',
      headers,
      timeout
    }, res => {
      let body = '';
      res.setEncoding('utf8');
      res.on('data', chunk => { body += chunk; });
      res.on('end', () => resolve({ statusCode: res.statusCode || 0, body }));
    });

    req.on('timeout', () => {
      req.destroy(new Error(`Timed out after ${timeout} ms`));
    });
    req.on('error', reject);
    req.end();
  });
}
