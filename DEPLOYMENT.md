# China-only deployment checklist

## 1. Supabase

- Create a NEW Supabase project for the China customer.
- Run `supabase/china_schema.sql`.
- Create the first Auth user.
- Insert the corresponding `public.users` row as `Super Admin`.
- Deploy the `reset-password` Edge Function.
- Verify RLS before giving the URL to customers.

## 2. Vercel

Create a new Vercel Project from the same GitHub repository if you want the China app to have its own URL while the old combined app stays online.

Environment variables:

- `VITE_APP_MODE=china`
- `VITE_SUPABASE_URL=<China Supabase URL>`
- `VITE_SUPABASE_ANON_KEY=<China Supabase anon key>`

The included `vercel.json` rewrites SPA routes to `/index.html`, so direct refreshes such as `/cn-orders/....` do not produce a Vercel 404.

## 3. Test accounts

Test separately:

- Super Admin
- Manager
- Supervisor
- Senior Officer
- Officer
- Customer

Confirm that:

- Staff cannot access customer-only records.
- Customer sees only their own packages/orders.
- Customer never sees scanner/internal staff fields.
- China deployment contains no AIR routes.
- Password reset forces a customer/staff account to choose a new password on next login.
