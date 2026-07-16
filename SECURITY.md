# Security Policy

## Supported Deployment

The supported production deployment is the static GitHub Pages bundle produced by the dev repository promotion workflow and deployed from the isolated production repository.

Development-only SQL files, architecture docs, screenshots, and local notes must not be published with the production bundle.

## Reporting A Vulnerability

Email `taint.calculator@gmail.com` with:

- Affected URL, commit, or workflow run.
- Reproduction steps.
- Expected and actual impact.
- Whether any Supabase data, auth flow, or production deployment was affected.

Do not include real user secrets or personal data in reports. Use test accounts and redacted screenshots where possible.

## Security Baseline

TAINT follows the SSDLC documented in `docs/secure-sdlc.md`.

Before release, run:

```powershell
node scripts/validate-security-posture.mjs
node scripts/validate-factor-registry.mjs
node --check assets/js/app.js
node --check assets/js/factor-registry.js
node --check assets/js/supabase-runtime-config.js
node --check scripts/write-supabase-config.mjs
```

## Secret Handling

Only browser-safe Supabase URL and publishable/anon keys may appear in front-end files. Never commit Supabase `service_role` keys, database passwords, SMTP credentials, GitHub tokens, or private user data.

Production secrets and variables must live in GitHub repository secrets/variables and Supabase settings.
