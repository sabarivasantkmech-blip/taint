# Supabase Front-End Connection

## Files

- `taint_supabase_schema.sql` creates the database tables, RPCs, grants, and Row Level Security policies.
- `supabase-config.js` holds the browser-safe Supabase Project URL and anon/public key.
- `index.html` loads `supabase-config.js` and writes UI data to Supabase when configured.

## Setup

1. Open Supabase SQL Editor.
2. Run `taint_supabase_schema.sql`.
3. Open Supabase Project Settings -> API.
4. Copy the Project URL and anon public key.
5. Put them in `supabase-config.js`:

```js
window.TAINT_SUPABASE_CONFIG = {
  environment: 'dev',
  url: 'https://your-project-ref.supabase.co',
  anonKey: 'your-anon-public-key',
  environments: {
    dev: {
      label: 'Development',
      url: 'https://your-dev-project-ref.supabase.co',
      anonKey: 'your-dev-anon-public-key',
      siteUrl: 'https://sabarivasantkmech-blip.github.io/taint/index.html'
    },
    prod: {
      label: 'Production',
      url: '',
      anonKey: '',
      siteUrl: 'https://your-production-domain.example/index.html'
    }
  },
  auth: {
    siteUrl: 'https://sabarivasantkmech-blip.github.io/taint/index.html',
    validateResetEmail: true,
    resetEmailCooldownMs: 60000,
    adminOwnerEmails: ['owner@example.com'],
    adminOwnerUserIds: [],
    oauthProviders: [],
    enterpriseSso: false
  }
};
```

Do not use the `service_role` key in the front end.
The current checked-in Supabase project is the `dev` environment. Keep `prod` empty until a separate production project and domain are ready.

## Auth Providers

Email/password sign-up uses Supabase Auth when configured. Social sign-in buttons are hidden unless the matching providers are enabled in both places:

1. Supabase Dashboard -> Authentication -> Providers.
2. `supabase-config.js`:

```js
auth: {
  oauthProviders: ['google', 'github'],
  enterpriseSso: false
}
```

If a social provider is not enabled in Supabase, Supabase returns `Unsupported provider: provider is not enabled`. Keeping the provider out of `oauthProviders` prevents users from seeing a broken button.

OAuth and SSO must be tested from `http://localhost`, `127.0.0.1`, or a deployed `https://` URL. They will not work correctly from `file://`.

Taint Admin is an owner-only UI surface. It appears only when a Supabase-authenticated user matches `adminOwnerEmails` or `adminOwnerUserIds` in `supabase-config.js`.

## Sign-Up Email And Forgot Password

TAINT does not email plaintext login passwords. Supabase stores password hashes and sends secure confirmation/recovery links.

Sign-up:

1. User enters name, email, and password.
2. `supabase.auth.signUp()` creates the user and sends the Supabase confirmation/acknowledgement email when email confirmation is enabled.
3. User clicks the confirmation link and returns to the configured redirect URL.

Forgot password:

1. User clicks `Forgot password?`.
2. The app calls `taint_account_email_exists(email)` to verify that the address belongs to a Supabase Auth user.
3. The app calls `supabase.auth.resetPasswordForEmail(email, { redirectTo })` once per cooldown window.
4. User follows the email link back to the configured `siteUrl`.
5. The app shows a new-password form and calls `supabase.auth.updateUser({ password })`.

For reliable production emails, configure Supabase Authentication -> SMTP Settings. The default Supabase email service is suitable for testing and has limits.

## Browser Health Check

After opening the app, run this in the browser console:

```js
await window.taintCheckSupabase()
```

Expected successful result:

```js
{ ok: true, reason: 'Supabase connected' }
```

If the config is still a placeholder, the app stays in local-only mode and returns:

```js
{ ok: false, reason: 'Supabase config missing. Fill supabase-config.js.' }
```

## GitHub Pages Deployment URLs

The checked-in frontend is configured for:

```js
url: 'https://pywjwsrjzgkvgplkxdry.supabase.co'
anonKey: 'sb_publishable_Jn4aL5TQIzd6mPm5JayQeA_M7dzGBn9'
```

For Supabase Auth redirects, open Supabase Dashboard -> Authentication -> URL Configuration and set:

```text
Site URL:
https://sabarivasantkmech-blip.github.io/taint/index.html
```

Add these Redirect URLs:

```text
https://sabarivasantkmech-blip.github.io/taint/**
```

Do not point Supabase email redirects at `www.taint.com` unless that custom domain is owned, verified in GitHub Pages, and serving this repository over HTTPS.
