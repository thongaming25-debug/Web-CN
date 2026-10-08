# CargoBridge China — Supabase connection

This deployment is China-only and must use its own Supabase project.

## 1. Create the local environment file

Copy `.env.example` to `.env` and replace the two placeholders:

```env
VITE_APP_MODE=china
VITE_SUPABASE_URL=https://YOUR-CHINA-PROJECT.supabase.co
VITE_SUPABASE_ANON_KEY=YOUR_CHINA_SUPABASE_ANON_KEY
```

Use the **Project URL** and **anon/public key** from:

Supabase Dashboard → Project Settings → API

Do not put a `service_role` key in `.env` or frontend code.

## 2. Supabase client location

The application connects through:

`src/lib/supabaseClient.js`

The client enables persistent sessions, automatic token refresh, and auth callback detection.

The app intentionally fails fast if the Supabase URL/key is missing or if `VITE_APP_MODE` is not `china`.

## 3. Vercel

In the China Vercel project, add the same variables under:

Settings → Environment Variables

- `VITE_APP_MODE` = `china`
- `VITE_SUPABASE_URL` = your China Supabase Project URL
- `VITE_SUPABASE_ANON_KEY` = your China Supabase anon/public key

Redeploy after changing environment variables.
