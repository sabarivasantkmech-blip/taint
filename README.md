# TAINT

TAINT is a browser-based carbon emissions calculator for Chennai and other city contexts. It includes commute emissions, route lookup, workplace and household footprint calculators, My Taint profile tracking, feedback capture, and optional Supabase-backed persistence.

## Files

- `index.html` - deployable application entry point.
- `supabase-config.js` - browser-safe Supabase Project URL and anon key placeholder.
- `taint_supabase_schema.sql` - Supabase/Postgres schema, RPCs, grants, and Row Level Security policies.
- `supabase_frontend_connection.md` - setup steps for connecting the front end to Supabase.
- `dependency-security-scan.md` - dependency scan and vulnerability mitigation notes.

## Supabase Setup

1. Create a Supabase project.
2. Run `taint_supabase_schema.sql` in SQL Editor.
3. Paste your Project URL and anon public key into `supabase-config.js`.
4. Open the app and run `await window.taintCheckSupabase()` in the browser console.

Do not put the Supabase `service_role` key in any front-end file.
