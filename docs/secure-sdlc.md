# Secure Software Development Lifecycle

This SSDLC applies to the entire TAINT application: static browser UI, Supabase Auth and Postgres, SQL migrations, GitHub Pages deployment, scientific factor registry, and dev-to-prod promotion.

## Standards Baseline

TAINT uses these references as its security vocabulary:

- NIST SSDF SP 800-218: secure software practices that can be integrated into any SDLC.
- OWASP SAMM: maturity model for measuring and improving a security program.
- OWASP ASVS: technical verification requirements for web applications.
- OWASP Secure Coding Practices: implementation-level secure coding checklist.

## Security Objectives

- Protect user accounts, calculation history, sensitive profile records, and uploaded artifacts.
- Prevent unauthorized reads/writes across Supabase users and environments.
- Keep production isolated from development data, SQL files, and local artifacts.
- Make every production release reviewable, reproducible, and approval-gated.
- Keep scientific claims honest by validating the factor registry separately from application code.

## Lifecycle Practices

### 1. Plan And Requirements

- Classify each feature as public UI, authenticated user data, admin-only data, scientific methodology, or release infrastructure.
- Write security acceptance criteria before implementation:
  - Authenticated data must be user-owned through Supabase RLS.
  - Admin-only surfaces must require Supabase user allowlists.
  - Front-end storage must not contain passwords, service tokens, or sensitive raw records.
  - Scientific factors must include source, boundary, confidence, and scale status.
- Use the release checklist in `docs/security-release-checklist.md` for any production promotion.

### 2. Design And Threat Modeling

Perform a short threat model for features that touch:

- Supabase Auth, sessions, password reset, OAuth, SSO, or redirects.
- Postgres tables, RPC functions, RLS policies, storage buckets, or migrations.
- `innerHTML`, `srcdoc`, `window.open`, URL parameters, map/geocoder data, or third-party API data.
- GitHub Actions, Pages deployment, production promotion, or generated configs.
- Scientific factor values that drive India-wide claims or product recommendations.

Document:

- Assets.
- Entry points.
- Trust boundaries.
- Abuse cases.
- Mitigations.
- Required tests.

### 3. Implementation

- Prefer `textContent`, DOM APIs, and `escapeHTML` for rendered user or third-party data.
- Treat localStorage/sessionStorage as readable by same-origin scripts; never store passwords or long-lived secrets there.
- Keep Supabase writes behind signed-in user checks and server-side RLS.
- Keep SQL helper functions `SECURITY DEFINER` only when necessary, with fixed `search_path` and narrow grants.
- Use parameterized SQL and avoid dynamic SQL unless justified and reviewed.
- Keep public config browser-safe. Production config is generated from GitHub variables.
- Pin CDN dependencies to exact versions and include SRI where loaded from a CDN.
- Preserve CSP guardrails: `object-src 'none'`, `base-uri 'self'`, `form-action`, and explicit `connect-src`.
- Keep the production bundle limited to `index.html`, `supabase-config.js`, `assets/`, `vendor/`, `.nojekyll`, and optional `CNAME`.

### 4. Verification

Every PR or release candidate should pass:

```powershell
node scripts/validate-security-posture.mjs
node scripts/validate-factor-registry.mjs
node --check assets/js/app.js
node --check assets/js/factor-registry.js
node --check assets/js/supabase-runtime-config.js
node --check scripts/write-supabase-config.mjs
```

Security review must include:

- Auth flow review for redirect, reset, confirmation, and sign-out changes.
- Storage review for localStorage/sessionStorage/cookies.
- XSS review for `innerHTML`, `srcdoc`, Leaflet popups, markdown-like rendering, and third-party API data.
- Supabase RLS review for new tables, RPCs, buckets, and policies.
- GitHub Actions review for permissions, token scopes, and production approval gates.
- Dependency review for CDN pins and local vendored code.

### 5. Release And Deployment

- Dev repository `main` deploys only the dev Pages app.
- Production is promoted by generated bundle PR into the isolated production repository.
- Production deployment requires a GitHub `production` environment approval.
- Production Supabase URL/key must be injected by GitHub variables, not committed.
- The production bundle must exclude SQL files, docs, screenshots, test artifacts, and development configs.

### 6. Operations And Monitoring

- Monitor GitHub Actions for failed validation, queued approval, or deployment failure.
- Monitor Supabase security advisor findings after migrations.
- Rotate Supabase publishable keys if they are unintentionally exposed outside expected public front-end use.
- Rotate GitHub production promotion tokens if workflow logs, PRs, or local machines expose them.
- Review factor registry sources at least every six months.

### 7. Incident Response

For suspected compromise:

1. Pause production promotion and deployment.
2. Identify affected commit, workflow, Supabase project, and user data surface.
3. Revoke or rotate affected tokens/secrets.
4. Patch dev, validate, promote through production PR, and require approval.
5. Record root cause and add a regression check.

## Current Risk Register

| Risk | Status | Required Control |
| --- | --- | --- |
| Static app uses CSP `'unsafe-inline'` | Accepted short term | Keep external scripts pinned/SRI; migrate inline handlers/scripts to external modules before tightening CSP |
| Browser storage can be read after XSS | Active control needed | Avoid sensitive localStorage; prefer Supabase Auth/session APIs and encrypted server-side storage |
| Leaflet popup XSS advisory on 1.9.4 | Mitigated | Keep `leaflet-popup-sanitize.js`; upgrade when upstream release exists |
| Password reset email enumeration | Needs product/security decision | Prefer neutral reset response in production |
| Scientific factors include screening proxies | Controlled | Registry marks confidence, scale status, and `claims_allowed` |
| Production token can write prod repo | Controlled | Fine-grained token, GitHub secret, prod PR review, production environment approval |

## Source References

- NIST SSDF SP 800-218: https://csrc.nist.gov/pubs/sp/800/218/final
- OWASP SAMM: https://owasp.org/www-project-samm/
- OWASP ASVS: https://owasp.org/www-project-application-security-verification-standard/
- OWASP Secure Coding Practices: https://owasp.org/www-project-secure-coding-practices-quick-reference-guide/
