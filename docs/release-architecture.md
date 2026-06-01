# Release Architecture

This repo now supports a dev-to-prod release path with approval gates.

## Recommended Isolation Model

For the strongest isolation, use two repositories:

- `taint-dev` for day-to-day development, dev Supabase, and preview artifacts.
- `taint-prod` for production Pages, production Supabase, and the custom domain.

This current repo can still work as the production repo. A separate production repo is useful when you want repository-level isolation, separate write permissions, and a production-only audit trail.

## Branch Flow In This Repo

- `develop` is the dev integration branch.
- `main` is the production branch.
- `Dev CI` runs for `develop` pushes and PRs.
- `Promote Dev To Prod` creates a `develop` -> `main` release PR.
- `Deploy Production Pages` validates `main`, waits for `production` environment approval, then deploys GitHub Pages.

## Required GitHub Settings

Configure these once in GitHub:

1. Settings -> Branches -> protect `main`.
2. Require pull request before merging.
3. Require at least one approval.
4. Require status checks before merging: `Static checks and dev artifact` and `Validate production bundle`.
5. Restrict direct pushes to `main`.
6. Settings -> Environments -> create `production`.
7. Add required reviewer(s) for `production`.
8. Enable prevent self-review if available.
9. Limit `production` deployment branches to `main`.

GitHub documents environment approvals and required reviewers in the deployment environments guide.

## Custom Domain

Do not add `CNAME` until the domain is purchased and DNS is ready. A wrong `CNAME` can break the live GitHub Pages URL.

Recommended domain options:

- `taintcarbon.in`
- `taintcarbon.com`
- `taintcalculator.in`
- `mytaint.in`

Preferred canonical domain: `www.taintcarbon.in`, with the apex `taintcarbon.in` redirecting to `www`.

For GitHub Pages DNS:

- `www` CNAME -> `sabarivasantkmech-blip.github.io`
- Apex `@` A records -> GitHub Pages IPs from current GitHub docs
- Enable Enforce HTTPS after GitHub verifies the domain

After DNS is correct, add a root `CNAME` file containing only the chosen domain and update Supabase Auth URL Configuration:

- Site URL: `https://www.taintcarbon.in/index.html`
- Redirect URL: `https://www.taintcarbon.in/**`

## Supabase Environment Split

- Dev Supabase: `pywjwsrjzgkvgplkxdry`
- Prod Supabase: `oavkdvuvlupawxhjtowh`

The production Pages bundle uses `environment: 'prod'`. The dev CI artifact rewrites the copied bundle to `environment: 'dev'` without changing source files.
