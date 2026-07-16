import { readFileSync, existsSync } from 'node:fs';
import vm from 'node:vm';

const read = path => readFileSync(path, 'utf8');
const errors = [];
const warnings = [];

function stripComments(contents) {
  return contents
    .replace(/<!--[\s\S]*?-->/g, '')
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/^\s*\/\/.*$/gm, '');
}

function requireFile(path) {
  if (!existsSync(path)) errors.push(`missing required file: ${path}`);
}

function assert(condition, message) {
  if (!condition) errors.push(message);
}

function warn(condition, message) {
  if (!condition) warnings.push(message);
}

[
  'index.html',
  'assets/js/app.js',
  'assets/js/factor-registry.js',
  'assets/js/leaflet-popup-sanitize.js',
  'assets/js/supabase-runtime-config.js',
  'scripts/write-supabase-config.mjs',
  'scripts/check-dev-db.mjs',
  'scripts/validate-factor-registry.mjs',
  'taint_supabase_schema.sql',
  'supabase_business_storage_migration.sql',
  'supabase_sensitive_data_encryption.sql',
  'supabase_security_advisor_followup.sql',
  'supabase_policy_performance_followup.sql',
  'supabase_regression_data_followup.sql',
  'supabase_user_owned_logs_rls_followup.sql',
  'docs/secure-sdlc.md',
  'docs/security-release-checklist.md',
  'SECURITY.md'
].forEach(requireFile);

const index = read('index.html');
const app = read('assets/js/app.js');
const runtimeConfig = read('assets/js/supabase-runtime-config.js');
const devWorkflow = read('.github/workflows/dev-ci.yml');
const pagesWorkflow = read('.github/workflows/pages.yml');
const promoteWorkflow = read('.github/workflows/promote-prod.yml');
const keepaliveWorkflow = read('.github/workflows/dev-db-keepalive.yml');
const prodWorkflow = read('prod-repo-template/.github/workflows/pages.yml');

const csp = index.match(/Content-Security-Policy" content="([^"]+)"/)?.[1] || '';
assert(csp.includes("default-src 'self'"), 'CSP must default to self');
assert(csp.includes("object-src 'none'"), 'CSP must disable object-src');
assert(csp.includes("base-uri 'self'"), 'CSP must pin base-uri to self');
assert(csp.includes('form-action'), 'CSP must define form-action');
assert(csp.includes("worker-src 'none'"), 'CSP must disable workers unless intentionally needed');
assert(csp.includes('https://*.supabase.co'), 'CSP connect-src must allow Supabase explicitly');
warn(!csp.includes("'unsafe-inline'"), "CSP still uses 'unsafe-inline'; accepted only until inline scripts/styles are removed");

assert(index.includes('@supabase/supabase-js@2.106.1'), 'Supabase JS must be pinned to the reviewed version');
assert(/supabase-js@2\.106\.1[^>]+integrity="sha384-[^"]+"/.test(index), 'Supabase CDN script must include SRI');
assert(/supabase-js@2\.106\.1[^>]+crossorigin="anonymous"/.test(index), 'Supabase CDN script must include crossorigin');
assert(/supabase-js@2\.106\.1[^>]+referrerpolicy="no-referrer"/.test(index), 'Supabase CDN script must include no-referrer');

const sanitizerPos = index.indexOf('leaflet-popup-sanitize.js');
const factorPos = index.indexOf('factor-registry.js');
const appPos = index.indexOf('assets/js/app.js');
assert(sanitizerPos > -1 && sanitizerPos < appPos, 'Leaflet popup sanitizer must load before app.js');
assert(factorPos > -1 && factorPos < appPos, 'factor-registry.js must load before app.js');

const publishedFrontend = [
  ['index.html', index],
  ['assets/js/app.js', app],
  ['assets/js/supabase-runtime-config.js', runtimeConfig],
  ['assets/js/factor-registry.js', read('assets/js/factor-registry.js')],
  ['supabase-config.js', read('supabase-config.js')]
];
const secretPatterns = [
  /service[_-]?role/i,
  /SUPABASE_SERVICE_ROLE/i,
  /postgres:\/\/|postgresql:\/\//i,
  /ghp_[A-Za-z0-9_]+/,
  /github_pat_[A-Za-z0-9_]+/
];
for (const [path, contents] of publishedFrontend) {
  const codeWithoutComments = stripComments(contents);
  for (const pattern of secretPatterns) {
    assert(!pattern.test(codeWithoutComments), `${path} appears to contain a forbidden secret pattern: ${pattern}`);
  }
}

assert(app.includes('escapeHTML'), 'app.js must keep escapeHTML helper');
assert(index.includes('leaflet-popup-sanitize.js'), 'index.html must load Leaflet popup sanitizer');

for (const [name, workflow] of [
  ['dev-ci', devWorkflow],
  ['pages', pagesWorkflow],
  ['promote-prod', promoteWorkflow]
]) {
  assert(workflow.includes("node-version: '22'"), `${name} workflow must use Node 22`);
  assert(workflow.includes('node --check assets/js/app.js'), `${name} workflow must syntax-check app.js`);
  assert(workflow.includes('node --check assets/js/factor-registry.js'), `${name} workflow must syntax-check factor-registry.js`);
  assert(workflow.includes('node --check scripts/check-dev-db.mjs'), `${name} workflow must syntax-check check-dev-db.mjs`);
  assert(workflow.includes('node scripts/validate-factor-registry.mjs'), `${name} workflow must validate factor registry`);
  assert(workflow.includes('node scripts/validate-security-posture.mjs'), `${name} workflow must validate security posture`);
}

assert(keepaliveWorkflow.includes('schedule:'), 'dev DB keepalive workflow must be scheduled');
assert(keepaliveWorkflow.includes('workflow_dispatch:'), 'dev DB keepalive workflow must support manual dispatch');
assert(keepaliveWorkflow.includes("cron: '15 3 * * *'"), 'dev DB keepalive workflow must run daily at the expected time');
assert(keepaliveWorkflow.includes('node --check scripts/check-dev-db.mjs'), 'dev DB keepalive workflow must syntax-check check-dev-db.mjs');
assert(keepaliveWorkflow.includes('node scripts/check-dev-db.mjs'), 'dev DB keepalive workflow must run check-dev-db.mjs');
assert(keepaliveWorkflow.includes('contents: read'), 'dev DB keepalive workflow must use read-only contents permission');

assert(devWorkflow.includes('permissions:') && devWorkflow.includes('contents: read'), 'dev CI must use minimal contents read permission');
assert(pagesWorkflow.includes('pages: write') && pagesWorkflow.includes('id-token: write'), 'dev Pages workflow must use Pages OIDC permissions');
assert(promoteWorkflow.includes('PROD_REPO_TOKEN'), 'promotion workflow must use PROD_REPO_TOKEN from secrets');
assert(promoteWorkflow.includes('test ! -e _prod_site/taint_supabase_schema.sql'), 'production promotion must exclude SQL files');
assert(promoteWorkflow.includes('test ! -e _prod_site/README.md'), 'production promotion must exclude dev README');
assert(prodWorkflow.includes('production-approval'), 'production template must include approval job');
assert(prodWorkflow.includes('environment:') && prodWorkflow.includes('production'), 'production template must use production environment');
assert(prodWorkflow.includes('Validate production static bundle'), 'production template must validate static bundle');
assert(prodWorkflow.includes('node --check assets/js/factor-registry.js'), 'production template must syntax-check factor-registry.js');

try {
  const registryContext = { window: {} };
  vm.createContext(registryContext);
  vm.runInContext(read('assets/js/factor-registry.js'), registryContext, { filename: 'factor-registry.js' });
  const registry = registryContext.window.TAINT_FACTOR_REGISTRY;
  assert(!!registry, 'factor registry must create window.TAINT_FACTOR_REGISTRY');
  const missing = registry?.factors?.filter(factor =>
    registry.required_fields.some(field => !(field in factor) || factor[field] === '' || factor[field] === undefined || factor[field] === null)
  ) || [];
  assert(missing.length === 0, `factor registry has ${missing.length} records missing required fields`);
} catch (error) {
  errors.push(`factor registry validation failed: ${error.message}`);
}

const report = {
  checks: 'security posture',
  warnings: warnings.length,
  errors: errors.length
};
console.log(JSON.stringify(report, null, 2));

if (warnings.length) {
  console.warn('\nWarnings:');
  warnings.forEach(item => console.warn(`- ${item}`));
}

if (errors.length) {
  console.error('\nErrors:');
  errors.forEach(item => console.error(`- ${item}`));
  process.exit(1);
}
