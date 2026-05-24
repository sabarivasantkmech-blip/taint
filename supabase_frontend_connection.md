# Supabase Front-End Connection

## Files

- `taint_supabase_schema.sql` creates the database tables, RPCs, grants, and Row Level Security policies.
- `supabase-config.js` holds the browser-safe Supabase Project URL and anon/public key.
- `chennai_carbon_calculator.hardened.html` loads `supabase-config.js` and writes UI data to Supabase when configured.

## Setup

1. Open Supabase SQL Editor.
2. Run `taint_supabase_schema.sql`.
3. Open Supabase Project Settings -> API.
4. Copy the Project URL and anon public key.
5. Put them in `supabase-config.js`:

```js
window.TAINT_SUPABASE_CONFIG = {
  url: 'https://your-project-ref.supabase.co',
  anonKey: 'your-anon-public-key'
};
```

Do not use the `service_role` key in the front end.

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
