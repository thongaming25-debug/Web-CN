# CargoBridge China Purchase — Standalone Build

This is the China-only build extracted from the existing CargoBridge logistics app.

## Scope

- China Purchase Orders
- China TK / Packages
- Inbound Origin / Outbound Origin
- Containers / container items
- Cambodia warehouse / arrival / sorting / delivery
- Customer Portal
- Customer accounts / addresses / warehouse route data
- Staff/Admin authentication
- Super Admin / Manager / Supervisor / Senior Officer / Officer roles
- Role & Permission Management
- Customer password reset with forced password change
- Audit logs, notifications, wallet/payment records, settings
- Supabase RLS

AIR / Indonesia is intentionally excluded from this deployment and database.

## China order workflow

`Order Processing → Purchased → Shipping to China WH → Inbound Origin → Outbound Origin → Arrive WH-KH → Inbound WH-KH → Complete Order`

From `Inbound Origin` onward, TK/package status is the source of truth for the order status.

## Local setup

1. Create a **new Supabase project** for the China customer.
2. Run `supabase/china_schema.sql` in Supabase SQL Editor.
3. Create the first Super Admin in Supabase Authentication, then insert the matching row into `public.users` with `role = 'Super Admin'`.
4. Copy `.env.example` to `.env` and set the China Supabase URL/key.
5. Run `npm install` then `npm run dev`.

## Vercel

Create a separate Vercel Project for the China deployment from the same GitHub repository if the existing combined deployment must remain untouched.

Set:

```env
VITE_APP_MODE=china
VITE_SUPABASE_URL=<CHINA_SUPABASE_URL>
VITE_SUPABASE_ANON_KEY=<CHINA_SUPABASE_ANON_KEY>
```

## Password reset

Deploy `supabase/functions/reset-password` as the `reset-password` Edge Function. The service-role key stays server-side in Supabase; it must never be placed in Vercel/browser environment variables.
