import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const registryPath = new URL('../assets/js/factor-registry.js', import.meta.url);
const code = readFileSync(registryPath, 'utf8');
const context = { window: {} };
vm.createContext(context);
vm.runInContext(code, context, { filename: 'factor-registry.js' });

const registry = context.window.TAINT_FACTOR_REGISTRY;
if (!registry) throw new Error('TAINT_FACTOR_REGISTRY was not created.');

const allowedConfidence = new Set(['high', 'medium', 'low']);
const allowedScaleStatus = new Set(['audit_candidate', 'india_screening_ready', 'screening_only']);
const requiredDomains = [
  'electricity',
  'commute_vehicle',
  'electric_mobility',
  'home',
  'workplace',
  'my_taint',
  'digital',
  'routing_adjustment',
  'adjustment',
  'impact_proxy'
];

const errors = [];
const warnings = [];
const ids = new Set();

for (const factor of registry.factors) {
  for (const field of registry.required_fields) {
    if (!(field in factor) || factor[field] === '' || factor[field] === undefined || factor[field] === null) {
      errors.push(`${factor.id || '(missing id)'} missing required field ${field}`);
    }
  }

  if (ids.has(factor.id)) errors.push(`${factor.id} is duplicated`);
  ids.add(factor.id);

  if (!allowedConfidence.has(factor.confidence)) errors.push(`${factor.id} has invalid confidence ${factor.confidence}`);
  if (!allowedScaleStatus.has(factor.scale_status)) errors.push(`${factor.id} has invalid scale_status ${factor.scale_status}`);
  if (typeof factor.value !== 'number' || !Number.isFinite(factor.value)) errors.push(`${factor.id} value must be a finite number`);
  if (typeof factor.year !== 'number' || factor.year < 1990 || factor.year > 2035) errors.push(`${factor.id} year looks invalid`);
  if (!/^https?:\/\//.test(factor.source_url)) errors.push(`${factor.id} source_url must be absolute http(s)`);
  if (factor.uncertainty_pct < 0 || factor.uncertainty_pct > 1) errors.push(`${factor.id} uncertainty_pct must be 0..1`);
  if (factor.confidence === 'low' && factor.claims_allowed) errors.push(`${factor.id} low-confidence factor cannot allow claims`);
  if (factor.source_type === 'model_assumption' && factor.claims_allowed) errors.push(`${factor.id} model assumptions cannot allow claims`);
  if (factor.source_type === 'model_assumption' && factor.scale_status !== 'screening_only') errors.push(`${factor.id} model assumptions must be screening_only`);
  if (factor.scale_status === 'screening_only' && !factor.notes) warnings.push(`${factor.id} screening_only factor should explain its limitation`);
}

for (const domain of requiredDomains) {
  if (!registry.factors.some(factor => factor.domain === domain)) errors.push(`missing required domain ${domain}`);
}

const byScale = registry.factors.reduce((acc, factor) => {
  acc[factor.scale_status] = (acc[factor.scale_status] || 0) + 1;
  return acc;
}, {});

const byConfidence = registry.factors.reduce((acc, factor) => {
  acc[factor.confidence] = (acc[factor.confidence] || 0) + 1;
  return acc;
}, {});

const report = {
  factor_count: registry.factors.length,
  domain_count: new Set(registry.factors.map(factor => factor.domain)).size,
  by_scale_status: byScale,
  by_confidence: byConfidence,
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
