import { writeFileSync } from 'node:fs';
import { dirname } from 'node:path';
import { mkdirSync } from 'node:fs';

const outPath = process.argv[2] || 'supabase-config.js';
const envName = (process.env.TAINT_ENV || 'dev').toLowerCase();
const adminEmails = (process.env.TAINT_ADMIN_OWNER_EMAILS || 'sabarivasantk27@gmail.com')
  .split(',')
  .map(value => value.trim())
  .filter(Boolean);

const settings = {
  dev: {
    label: 'Development',
    url: process.env.TAINT_DEV_SUPABASE_URL || 'https://pywjwsrjzgkvgplkxdry.supabase.co',
    anonKey: process.env.TAINT_DEV_SUPABASE_KEY || 'sb_publishable_Jn4aL5TQIzd6mPm5JayQeA_M7dzGBn9',
    siteUrl: process.env.TAINT_DEV_SITE_URL || 'https://sabarivasantkmech-blip.github.io/taint/index.html'
  },
  prod: {
    label: 'Production',
    url: process.env.TAINT_PROD_SUPABASE_URL || '',
    anonKey: process.env.TAINT_PROD_SUPABASE_KEY || '',
    siteUrl: process.env.TAINT_PROD_SITE_URL || ''
  }
};

if (!settings[envName]) {
  throw new Error(`Unsupported TAINT_ENV: ${envName}`);
}

if (envName === 'prod') {
  const requiredProdSettings = [
    ['url', 'TAINT_PROD_SUPABASE_URL'],
    ['anonKey', 'TAINT_PROD_SUPABASE_KEY'],
    ['siteUrl', 'TAINT_PROD_SITE_URL']
  ];
  for (const [key, envVarName] of requiredProdSettings) {
    if (!settings.prod[key]) throw new Error(`${envVarName} is required for prod config`);
  }
}

const active = settings[envName];
const publicEnvironments = {
  [envName]: active
};
const config = `// Generated browser-safe Supabase connection settings for TAINT.
// Do not put the Supabase service_role key in this file.
window.TAINT_SUPABASE_CONFIG = ${JSON.stringify({
  environment: envName,
  url: active.url,
  anonKey: active.anonKey,
  environments: publicEnvironments,
  auth: {
    siteUrl: active.siteUrl,
    validateResetEmail: true,
    resetEmailCooldownMs: 60000,
    adminOwnerEmails: adminEmails,
    adminOwnerUserIds: [],
    oauthProviders: [],
    enterpriseSso: false
  }
}, null, 2)};\n`;

mkdirSync(dirname(outPath), { recursive: true });
writeFileSync(outPath, config);
