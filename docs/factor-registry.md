# TAINT Factor Registry

`assets/js/factor-registry.js` is the audit layer for TAINT emission factors. Each factor record includes:

- `value`
- `unit`
- `geography`
- `year`
- `source_url`
- `source_type`
- `source_tier`
- `boundary`
- `confidence`
- `uncertainty_pct`
- `scale_status`
- `claims_allowed`
- `review_status`
- `reviewed_at`
- `next_review_due`
- `calculation_role`

## Confidence Rules

- `high`: official or directly measured factor with narrow interpretation.
- `medium`: recognized source or well-bounded model estimate.
- `low`: screening estimate, proxy, or local heuristic that needs validation before audited claims.

## Source Tier Rules

- Tier 1: official government source, international standard, or accounting standard.
- Tier 2: peer-reviewed literature, industry methodology, or well-documented domain model.
- Tier 3: transparent TAINT assumption. These factors must remain `screening_only`.

## Boundary Rules

- `tailpipe_operational`: direct vehicle-use emissions only.
- `use_phase_electricity`: electricity consumption converted with the selected grid factor.
- `location_based_scope2`: grid-average electricity emissions.
- `scope1_combustion`: direct fuel combustion.
- `scope3_*`: indirect value-chain estimate aligned to GHG Protocol categories.
- `lifecycle_proxy`: approximate lifecycle estimate used for screening.
- `model_assumption` or `screening_estimate`: transparent placeholder pending better India-specific evidence.
- `qualitative_pollution_visual_proxy`: visual impact only. This is not measured AQI, PM2.5, NOx, health risk, or carbon accounting.

## Scale Status Rules

- `audit_candidate`: source-linked and bounded enough for future audited methodology review.
- `india_screening_ready`: adequate for India-wide public estimates with uncertainty disclosure.
- `screening_only`: usable in the app only as a transparent estimate, proxy, or local heuristic.

`claims_allowed` is `false` for low-confidence values, model assumptions, distance/activity multipliers, qualitative impact proxies, and other screening-only factors.

## India-Wide Readiness

- Chennai commute: adequate for public estimate language.
- India commute: adequate for screening estimates when city grid intensity, mode, occupancy, and boundary are disclosed.
- Home: screening-only until India-specific lifecycle sources are added for diet, goods, water, waste, and appliances.
- Workplace: screening-only until sector benchmarks are replaced with India-specific datasets.
- Taint Buy/product savings: screening-only until product-level lifecycle data or validated product category factors are added.
- City Vision: visual proxy only; never present as AQI, PM2.5, NOx, or health exposure.

## Primary External Source Classes

- CEA CO2 Baseline Database for Indian grid electricity.
- GHG Protocol Scope 2 for purchased electricity accounting.
- GHG Protocol Scope 3 for value-chain, commuting, travel, purchased-goods, waste, and use-phase boundaries.
- IPCC 2006 Guidelines Volume 2 for stationary and mobile combustion inventory structure.
- ICAO environmental tools for aviation passenger emissions methodology.
- BEE appliance standards for Indian appliance energy assumptions.

## Scale-Up Standard

Before TAINT presents a factor as city-specific or India-wide, it should have:

1. A current official or peer-reviewed source where available.
2. A stated geography and year.
3. A clear boundary, especially tailpipe vs use-phase electricity vs lifecycle.
4. A confidence rating.
5. A replacement path when better state, city, fleet, or product data becomes available.

Run the registry validator after factor changes:

```powershell
node scripts/validate-factor-registry.mjs
```
