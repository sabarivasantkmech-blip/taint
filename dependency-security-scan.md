# Dependency and Vulnerability Scan

Date: 2026-05-24

## Scanned Artifact

- Source: `C:\Users\sabar\Downloads\chennai_carbon_calculator (1).html`
- Hardened output: `C:\Users\sabar\Documents\Taint\chennai_carbon_calculator.hardened.html`
- Project workspace initially contained no package manifest or source tree, so the scan focused on CDN/browser dependencies detected in the HTML artifact.

## Dependency Inventory

| Component | Original | Mitigated | Status |
| --- | ---: | ---: | --- |
| Leaflet | 1.9.4 | 1.9.4 | Latest npm version, but affected by CVE-2025-69993 in `bindPopup` when unsafe strings are passed to popups |
| @supabase/supabase-js | 2.45.4 | 2.106.1 | Updated to current npm version |
| Local Node.js runtime | 14.17.5 | Not changed | End-of-life; upgrade build tooling to an active LTS before adding a Node build pipeline |
| Local npm runtime | 6.14.14 | Not changed | Old npm coupled to EOL Node 14 |

## Findings

- npm audit of the original dependency set found 1 low-severity advisory:
  - `@supabase/supabase-js@2.45.4` pulls `@supabase/auth-js@2.65.0`.
  - Advisory: `GHSA-8r88-6cj9-9fh5` / `CVE-2025-48370`, insecure path routing from malformed user input.
  - Fixed by upgrading Supabase JS to `2.106.1`.
- Leaflet `1.9.4` is still the latest npm release, but advisory data marks versions up to and including `1.9.4` as affected by `CVE-2025-69993`, an XSS risk in `bindPopup`.
- The HTML artifact had no direct `bindPopup` calls, but future popup use would inherit the risk unless sanitized.
- Several dynamic strings from user input, browser storage, or third-party geocoding data were rendered with `innerHTML`.
- Existing Leaflet CSS/JS used SRI. Supabase JS did not.
- The existing Leaflet SRI hashes did not match the current cdnjs assets, causing browsers to reject Leaflet at runtime.
- Local Node.js `14.17.5` is EOL. Official Node.js docs state EOL releases stop receiving security patches.

## Mitigation Applied

- Updated Supabase CDN pin from `@supabase/supabase-js@2.45.4` to `2.106.1`.
- Added SRI, `crossorigin="anonymous"`, and `referrerpolicy="no-referrer"` to the Supabase CDN script.
- Recomputed and replaced Leaflet CSS/JS SRI hashes for the existing cdnjs URLs.
- Added a Leaflet `bindPopup` hardening shim that strips executable tags, event-handler attributes, and `javascript:` URLs from string popup content.
- Escaped dynamic autocomplete, feedback, and recent-activity strings before rendering them through `innerHTML`.
- Tightened the CSP slightly by removing `fonts.googleapis.com` from `script-src`, and adding `form-action` plus `worker-src`.

## Verification

- `npm audit` on the original dependency set: 1 low vulnerability.
- `npm audit` after Supabase upgrade: 0 vulnerabilities.
- Inline script syntax check: passed, 3 inline scripts parsed.
- Dependency inventory check: old Supabase `2.45.4` is no longer present in the hardened HTML.
- Browser smoke check loaded the hardened file over localhost and confirmed the title plus updated dependency pins.

## Residual Risk

- Leaflet remains at `1.9.4` because npm has no newer release. The app-side sanitizer mitigates popup XSS paths, but replace it with an upstream patched Leaflet release when one becomes available.
- The page is still a single-file static app with many inline scripts, so CSP must keep `'unsafe-inline'`. A future bundling step with external scripts and nonces/hashes would allow a stricter CSP.
- Upgrade local Node/npm tooling to an active LTS if this evolves into an npm-based build.

## Sources

- Node.js EOL policy and Node 14 EOL status: https://nodejs.org/en/about/eol
- Node.js release schedule: https://github.com/nodejs/Release
- Leaflet CVE-2025-69993 details: https://app.opencve.io/cve/CVE-2025-69993
- Debian tracker for CVE-2025-69993: https://security-tracker.debian.org/tracker/CVE-2025-69993
- npm registry queries performed with `npm view` and `npm audit`.
