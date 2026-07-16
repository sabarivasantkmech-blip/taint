# Calculation Benchmark

This benchmark compares TAINT calculation logic with public carbon-accounting references and common online calculator conventions. It is a scientific hygiene check, not a third-party certification.

Run it with:

```powershell
node scripts/benchmark-carbon-calculations.mjs
```

## Benchmark Sources

- Central Electricity Authority, CO2 Baseline Database for Indian grid electricity: https://cea.nic.in/cdm-co2-baseline-database/?lang=en
- GHG Protocol Scope 2 Guidance for location-based electricity accounting: https://ghgprotocol.org/scope-2-guidance
- IPCC 2006 Guidelines for fuel-combustion accounting structure: https://www.ipcc-nggip.iges.or.jp/public/2006gl/vol2.html
- ICAO Carbon Emissions Calculator methodology for passenger aviation: https://www.icao.int/environmental-protection/CarbonOffset/Pages/default.aspx
- EPA passenger-vehicle and fuel combustion references: https://www.epa.gov/greenvehicles/greenhouse-gas-emissions-typical-passenger-vehicle
- Sustainable Web Design digital-emissions model: https://sustainablewebdesign.org/calculating-digital-emissions/

## Current Alignment

- Electricity conversion follows the standard pattern used by Scope 2 calculators: `activity kWh x grid kgCO2e/kWh`.
- EV, rail, home appliance, and workplace equipment calculations use energy activity data converted with the selected city grid intensity.
- Commute trip and annualisation math follows the common online calculator pattern: `distance x emissions factor`, divided by occupancy where applicable, then annualised over commute days.
- Diesel generator and LPG combustion are benchmarked against fuel-combustion factors. Workplace LPG now uses `2.983 kgCO2e/kg LPG`, matching the home calculator and combustion-reference expectation.
- Site carbon now uses Sustainable Web Design v4's `0.300 kWh/GB` data-energy model instead of the older `1.805 kWh/GB` assumption.

## Remaining Cautions

- Some road-vehicle factors are direct g/km screening factors rather than fuel-use-derived calculations. This is acceptable for an India city screening calculator, but the paired `fuelPerKm` values used for cost display do not always imply the same CO2/litre as fuel-combustion calculators.
- Diet, shopping, furniture, delivery, water, and waste values remain screening estimates until India-specific lifecycle datasets are added.
- City Vision is a qualitative local-impact visual proxy only. It must not be described as measured AQI, PM2.5, NOx, exposure, or satellite-observed pollution.

## Pass Criteria

The benchmark script treats core accounting mismatches as failures. Road-vehicle fuel/cost cross-checks are advisory warnings because TAINT intentionally uses published or curated g/km factors for commute emissions and separate fuel-use estimates for cost.
