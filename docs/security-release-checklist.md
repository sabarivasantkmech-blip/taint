# Security Release Checklist

Use this checklist for every dev-to-prod promotion.

## Before PR Merge In Dev

- [ ] Security-sensitive changes are identified in the PR description.
- [ ] Auth/session/password reset behavior is reviewed if touched.
- [ ] Every new Supabase table has RLS enabled and user/admin ownership policies.
- [ ] Every new RPC has a reviewed `search_path`, grants, and caller model.
- [ ] Every new storage bucket has private/public intent documented.
- [ ] Dynamic rendering uses `textContent`, DOM APIs, or escaping.
- [ ] New external network hosts are added intentionally to CSP `connect-src`.
- [ ] New scripts/styles are pinned and have SRI when loaded from CDN.
- [ ] Factor changes pass `node scripts/validate-factor-registry.mjs`.
- [ ] Security posture passes `node scripts/validate-security-posture.mjs`.

## Before Production Promotion

- [ ] `main` dev CI passed.
- [ ] Supabase dev migrations were applied and validated.
- [ ] Production Supabase migration plan is known and reversible where possible.
- [ ] Production repository token is fine-grained and stored only as `PROD_REPO_TOKEN`.
- [ ] Production Supabase variables are configured in GitHub repository variables.
- [ ] Generated production bundle contains only static deploy files.
- [ ] Release PR in `taint-prod` is reviewed before merge.

## Production Approval

- [ ] Production workflow validation passed.
- [ ] GitHub `production` environment approval is from an authorized reviewer.
- [ ] Deployed Pages URL is checked after release.
- [ ] Supabase Auth redirect URL matches the production URL.
- [ ] Post-release smoke test covers sign-in, calculation, save, PDF/report, and recent items.

## Emergency Stop

- [ ] Do not approve production environment if validation is failing.
- [ ] If a bad release is merged, revert in prod repository or promote a fixed bundle from dev.
- [ ] Rotate Supabase/GitHub secrets if they may have leaked.
