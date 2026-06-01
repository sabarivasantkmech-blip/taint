# Release Architecture

This project uses separate repositories for development and production so frontend bundles, Supabase projects, approvals, and audit trails do not overlap.

## Repository Model

- `sabarivasantkmech-blip/taint` is the development repository. It stores source code, SQL migrations, docs, the dev Supabase config, and dev Pages deployment.
- `sabarivasantkmech-blip/taint-prod` is the production repository. It stores only the production static bundle, production runtime config, and production Pages workflow.
- `prod-repo-template/` contains the files needed to bootstrap or repair the production repository workflow.

## Code Migration Flow

1. Develop and test in `sabarivasantkmech-blip/taint`.
2. Run the manual `Promote Dev Bundle To Prod Repo` workflow from the dev repository.
3. The workflow uses `sabarivasantkmech-blip/taint-prod` as the production repository.
4. The workflow generates a production bundle using `PROD_SUPABASE_URL`, `PROD_SUPABASE_PUBLISHABLE_KEY`, and the production site URL.
5. The workflow pushes that bundle plus the production workflow template to a `release/dev-<sha>` branch in `sabarivasantkmech-blip/taint-prod`.
6. Review and merge the release PR in the production repository.
7. The production repository validates the bundle and waits for the `production` Environment approval before deploying Pages.

## Dev Branch Model

The dev repository does not need both `main` and `develop`.

- `main` is the dev trunk branch and deploys the dev Pages app.
- Feature and fix branches open PRs into `main`.
- Production releases are not made by merging dev `main` into a production branch. They are made by generating a bundle and opening a PR in `sabarivasantkmech-blip/taint-prod`.
- The old `develop` branch can remain as a dormant branch for history, but it is not required by CI or release workflows.

## Required GitHub Settings

Configure these once in both repositories where applicable:

1. Settings -> Branches -> protect `main`.
2. Require pull request before merging.
3. Require at least one approval.
4. In the dev repo, require `Static checks and dev artifact`.
5. In the prod repo, require `Validate production static bundle`.
6. Restrict direct pushes to `main`.
7. Settings -> Environments -> create `production` in the prod repo.
8. Add required reviewer(s) for `production`.
9. Enable prevent self-review if available.
10. Limit `production` deployment branches to `main`.

For `sabarivasantkmech-blip/taint-prod`, enable GitHub Pages once in Settings -> Pages by setting Build and deployment Source to `GitHub Actions`. Until that is enabled, the production workflow validates the bundle and skips the deploy step with a notice instead of failing red.

## Dev Repository Secrets And Variables

Add these to `sabarivasantkmech-blip/taint`:

- Secret `PROD_REPO_TOKEN`: a fine-grained GitHub token with contents write and pull request write access to `sabarivasantkmech-blip/taint-prod`.
- Variable `PROD_SUPABASE_URL`: `https://oavkdvuvlupawxhjtowh.supabase.co`.
- Variable `PROD_SUPABASE_PUBLISHABLE_KEY`: production Supabase publishable key.
- Variable `TAINT_ADMIN_OWNER_EMAILS`: comma-separated owner emails for production admin access.

## Production Repository Contents

The production repository should contain only:

- `index.html`
- `supabase-config.js`
- `assets/`
- `vendor/`
- `.nojekyll`
- `.github/workflows/pages.yml`
- optional `CNAME`

SQL files, architecture docs, local screenshots, and development notes stay in the dev repository.

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

After DNS is correct, add a root `CNAME` file in the production repository containing only the chosen domain and update Supabase Auth URL Configuration:

- Site URL: `https://www.taintcarbon.in/index.html`
- Redirect URL: `https://www.taintcarbon.in/**`

## Supabase Environment Split

- Dev Supabase: `pywjwsrjzgkvgplkxdry`
- Prod Supabase: `oavkdvuvlupawxhjtowh`

The development Pages bundle uses `environment: 'dev'` and `https://pywjwsrjzgkvgplkxdry.supabase.co`.

The production Pages bundle uses `environment: 'prod'` and `https://oavkdvuvlupawxhjtowh.supabase.co`.
