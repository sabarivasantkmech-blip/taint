# TAINT

TAINT is a browser-based carbon emissions calculator for Chennai and other city contexts. It includes commute emissions, route lookup, workplace and household footprint calculators, My Taint profile tracking, feedback capture, and optional Supabase-backed persistence.

## Files

- `index.html` - deployable application entry point.
- `assets/css/app.css` - application styles split out of the original standalone HTML.
- `assets/js/app.js` - application logic split out of the original standalone HTML.
- `assets/js/leaflet-popup-sanitize.js` - Leaflet popup hardening shim.
- `assets/js/supabase-runtime-config.js` - browser runtime wrapper for `supabase-config.js`.
- `archive/chennai_carbon_calculator_17_merged.html` - archived legacy single-file copy retained for comparison/reference.
- `archive/chennai_carbon_calculator_17.html` - archived standalone 17 source artifact retained for comparison/reference.
- `archive/chennai_carbon_calculator.hardened.html` - archived prior hardened build retained for comparison/reference.
- `supabase-config.js` - browser-safe Supabase Project URL and anon/publishable key placeholder.
- `taint_supabase_schema.sql` - Supabase/Postgres schema, RPCs, grants, and Row Level Security policies.
- `supabase_business_storage_migration.sql` - business entities, members, locations, app file metadata, and private JSON/media storage buckets.
- `supabase_security_advisor_followup.sql` - security follow-up for helper functions and visitor device reads.
- `supabase_policy_performance_followup.sql` - policy split and index follow-up for advisor findings.
- `supabase_sensitive_data_encryption.sql` - Supabase Vault-backed encrypted sensitive user records and RPC helpers.
- `supabase_frontend_connection.md` - setup steps for connecting the front end to Supabase.
- `dependency-security-scan.md` - dependency scan and vulnerability mitigation notes.
- `vendor/leaflet/1.9.4/` - local Leaflet JS/CSS/images used by the route map.

## Supabase Setup

1. Create a Supabase project.
2. Run `taint_supabase_schema.sql` in SQL Editor.
3. Run `supabase_business_storage_migration.sql`.
4. Run `supabase_sensitive_data_encryption.sql`.
5. Run `supabase_security_advisor_followup.sql`, `supabase_policy_performance_followup.sql`, then `supabase_regression_data_followup.sql`.
6. Paste your Project URL and anon or publishable public key into the `dev` environment in `supabase-config.js`. The checked-in project is treated as development; fill the `prod` environment only when a production Supabase project is ready.
7. Open the app and run `await window.taintCheckSupabase()` in the browser console.

Do not put the Supabase `service_role` key in any front-end file.

## Hosting

For local testing, serve the folder over HTTP so Auth redirects and browser storage behave like production:

```powershell
python -m http.server 8787
```

Then open `http://127.0.0.1:8787/index.html`.

For production, deploy `index.html`, `supabase-config.js`, `assets/`, and `vendor/`. The GitHub Pages workflow builds a clean `_site` bundle from only those files, so repository SQL/docs are not published with the site. In Supabase Authentication -> URL Configuration, set the Site URL to `https://sabarivasantkmech-blip.github.io/taint/index.html` and add `https://sabarivasantkmech-blip.github.io/taint/**` as an allowed Redirect URL.

Google, GitHub, and enterprise SSO buttons stay hidden until enabled in both Supabase Authentication -> Providers and `supabase-config.js`. Taint Admin stays hidden unless the signed-in Supabase user matches `auth.adminOwnerEmails` or `auth.adminOwnerUserIds`.

```js
environment: 'dev',
auth: {
  adminOwnerEmails: ['owner@example.com'],
  oauthProviders: ['google', 'github'],
  enterpriseSso: false
}
```

## Sign-Up And Password Reset

TAINT uses Supabase Auth for email/password accounts when Supabase is configured. Sign-up sends the normal Supabase confirmation/acknowledgement email to the new user. The app never emails plaintext passwords or credentials.

Forgot password uses Supabase's secure reset-link flow:

1. User clicks `Forgot password?`.
2. The app validates the address against Supabase Auth through `taint_account_email_exists`.
3. User receives one Supabase reset email per cooldown window.
4. The reset link opens the configured hosted app.
5. User enters a new password in the TAINT reset form.

For production email delivery, configure Supabase Authentication -> SMTP settings and add your deployed URL in Authentication -> URL Configuration.

## Release Flow

Use `develop` for dev integration and `main` for production. The workflows under `.github/workflows/` validate dev changes, create a `develop` -> `main` production release PR, and deploy GitHub Pages only after the `production` GitHub Environment is approved.

See `docs/release-architecture.md` for the full approval, custom domain, and dev/prod Supabase setup.
