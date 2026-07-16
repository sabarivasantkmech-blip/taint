import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const appPath = new URL('../assets/js/app.js', import.meta.url);
const registryPath = new URL('../assets/js/factor-registry.js', import.meta.url);
const appCode = readFileSync(appPath, 'utf8');
const registryCode = readFileSync(registryPath, 'utf8');

const context = { window: {} };
vm.createContext(context);
vm.runInContext(registryCode, context, { filename: 'factor-registry.js' });

const registry = context.window.TAINT_FACTOR_REGISTRY;
if (!registry) throw new Error('TAINT_FACTOR_REGISTRY was not created.');

function numberFromApp(regex, label) {
  const match = appCode.match(regex);
  if (!match) throw new Error(`Unable to read app constant: ${label}`);
  return Number(match[1]);
}

function registryValue(id) {
  const item = registry.byId(id);
  if (!item) throw new Error(`Unable to read registry factor: ${id}`);
  return Number(item.value);
}

function pctDiff(actual, reference) {
  return reference === 0 ? 0 : ((actual - reference) / reference) * 100;
}

function grade(actual, reference, tolerancePct, warningPct = tolerancePct * 2) {
  const diff = Math.abs(pctDiff(actual, reference));
  if (diff <= tolerancePct) return 'pass';
  if (diff <= warningPct) return 'warn';
  return 'fail';
}

const LITRES_PER_US_GALLON = 3.785411784;
const EPA_GASOLINE_KG_PER_LITRE = 8.887 / LITRES_PER_US_GALLON;
const EPA_DIESEL_KG_PER_LITRE = 10.180 / LITRES_PER_US_GALLON;

const chennaiGrid = registryValue('grid.chennai');
const evScooterEnergy = registryValue('commute.two.electric.ev_scoot');
const swdKwhPerGb = numberFromApp(/KWH_PER_GB\s*:\s*([0-9.]+)/, 'SC.KWH_PER_GB');
const wpLpg = numberFromApp(/lpgKgPerKg\s*:\s*([0-9.]+)/, 'WP_EF.lpgKgPerKg');
const hmLpg = numberFromApp(/lpgCO2PerKg\s*:\s*([0-9.]+)/, 'HM_EF.lpgCO2PerKg');
const wpDiesel = numberFromApp(/dieselKgPerL\s*:\s*([0-9.]+)/, 'WP_EF.dieselKgPerL');

const petrolSedanFuelPerKm = 0.0714;
const petrolSedanAppGPerKm = 121;
const petrolSedanFuelBasedGPerKm = petrolSedanFuelPerKm * EPA_GASOLINE_KG_PER_LITRE * 1000;

const benchmarks = [
  {
    id: 'grid_chennai_cea',
    actual: chennaiGrid,
    reference: 0.716,
    unit: 'kgCO2e/kWh',
    tolerancePct: 1,
    source: 'CEA CO2 Baseline Database value currently adopted by TAINT.'
  },
  {
    id: 'ev_scooter_grid_conversion',
    actual: evScooterEnergy * chennaiGrid * 1000,
    reference: 23.6,
    unit: 'gCO2e/km',
    tolerancePct: 2,
    source: 'GHG Protocol Scope 2 style electricity conversion: kWh/km x grid factor.'
  },
  {
    id: 'home_lpg_combustion',
    actual: hmLpg,
    reference: 2.983,
    unit: 'kgCO2e/kg LPG',
    tolerancePct: 1,
    source: 'IPCC stationary combustion style LPG factor used consistently for homes.'
  },
  {
    id: 'workplace_lpg_combustion',
    actual: wpLpg,
    reference: 2.983,
    unit: 'kgCO2e/kg LPG',
    tolerancePct: 1,
    source: 'Same LPG combustion basis as home calculator.'
  },
  {
    id: 'diesel_generator_combustion',
    actual: wpDiesel,
    reference: EPA_DIESEL_KG_PER_LITRE,
    unit: 'kgCO2/litre diesel',
    tolerancePct: 1,
    source: 'EPA diesel factor converted from kg/US gallon to kg/litre.'
  },
  {
    id: 'site_carbon_swd_v4_energy',
    actual: swdKwhPerGb,
    reference: 0.300,
    unit: 'kWh/GB',
    tolerancePct: 5,
    source: 'Sustainable Web Design v4 total operational plus embodied energy per GB.'
  },
  {
    id: 'commute_annualization_formula',
    actual: (petrolSedanAppGPerKm * 10 / 1000) * 2 * 260 / 1000,
    reference: 0.629,
    unit: 'tCO2e/year for 10 km one-way petrol sedan',
    tolerancePct: 1,
    source: 'Calculator formula: one-way trip kg x round trip x 260 commute days.'
  },
  {
    id: 'petrol_sedan_cost_vs_combustion_crosscheck',
    actual: petrolSedanAppGPerKm,
    reference: petrolSedanFuelBasedGPerKm,
    unit: 'gCO2/km',
    tolerancePct: 20,
    warningPct: 35,
    source: 'EPA gasoline combustion factor applied to TAINT fuelPerKm cost assumption.',
    severity: 'advisory'
  }
].map(item => {
  const status = grade(item.actual, item.reference, item.tolerancePct, item.warningPct);
  return {
    ...item,
    actual: Number(item.actual.toFixed(6)),
    reference: Number(item.reference.toFixed(6)),
    pct_diff: Number(pctDiff(item.actual, item.reference).toFixed(2)),
    status
  };
});

const requiredFailures = benchmarks.filter(item => item.status === 'fail' && item.severity !== 'advisory');
const advisoryWarnings = benchmarks.filter(item => item.status !== 'pass' && item.severity === 'advisory');

const report = {
  generated_at: new Date().toISOString(),
  benchmark_count: benchmarks.length,
  required_passed: benchmarks.length - requiredFailures.length - advisoryWarnings.length,
  required_failures: requiredFailures.length,
  advisory_warnings: advisoryWarnings.length,
  benchmarks
};

console.log(JSON.stringify(report, null, 2));

if (requiredFailures.length) {
  process.exitCode = 1;
}
