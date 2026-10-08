-- ============================================================
-- CargoBridge China — COMPLETE Supabase schema
-- China / Agency model ONLY
-- NO AIR / Indonesia
-- NO Container module
-- ============================================================
-- Run this in a NEW, EMPTY Supabase project.
-- Supabase Auth remains the source of truth for passwords.
-- Frontend must use only VITE_SUPABASE_URL + VITE_SUPABASE_ANON_KEY.
-- ============================================================

create extension if not exists pgcrypto;

-- ============================================================
-- 1. SEQUENCES
-- ============================================================
create sequence if not exists cn_order_seq;
create sequence if not exists order_no_seq;
create sequence if not exists tk_seq;

-- ============================================================
-- 2. ROLES / PERMISSIONS / STAFF
-- ============================================================
create table if not exists public.roles (
  name text primary key,
  level integer not null default 99,
  scope text not null default 'DEPARTMENT',
  status text not null default 'Active',
  description text,
  is_system boolean not null default false,
  permissions text[] not null default '{}',
  updated_at timestamptz not null default now()
);

create table if not exists public.users (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique references auth.users(id) on delete cascade,
  username text unique,
  name text not null,
  email text,
  phone text,
  role text not null default 'Officer' references public.roles(name),
  department text,
  warehouse_code text,
  status text not null default 'Active',
  must_change_password boolean not null default false,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- 3. CUSTOMERS / CUSTOMER SETTINGS
-- ============================================================
create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique references auth.users(id) on delete set null,
  customer_code text not null unique,
  name text not null,
  phone text,
  email text,
  status text not null default 'active',
  customer_role text default 'Customer',
  must_change_password boolean not null default false,
  avatar_url text,
  default_china_wh text,
  default_kh_branch text,
  balance numeric(14,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.customer_addresses (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  label text not null default 'Default',
  recipient_name text,
  phone text,
  province text,
  district text,
  commune text,
  address text,
  additional_info text,
  kh_branch_code text,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.customer_china_warehouse (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid unique references public.customers(id) on delete cascade,
  warehouse_code text,
  warehouse_name text,
  recipient_name text,
  phone text,
  province text,
  city text,
  district text,
  address text,
  additional_info text,
  copy_text text,
  status text not null default 'Active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.customer_roles (
  name text primary key,
  description text,
  denied text[] not null default '{}',
  status text not null default 'Active',
  updated_at timestamptz not null default now()
);

create table if not exists public.customer_features (
  key text primary key,
  label text,
  enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

-- ============================================================
-- 4. WAREHOUSES / ROUTING
-- ============================================================
create table if not exists public.warehouses (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  type text not null default 'cambodia',
  country text,
  province text,
  district text,
  commune text,
  address text,
  map_url text,
  status text not null default 'Active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.warehouse_history (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null,
  ref text not null,
  field text,
  old_code text,
  new_code text,
  changed_by text,
  reason text,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 5. SHIPPING PARTNERS — AGENCY REPLACEMENT FOR CONTAINER
-- ============================================================
create table if not exists public.shipping_partners (
  id uuid primary key default gen_random_uuid(),
  partner_code text unique,
  name text not null,
  country text default 'China',
  contact_person text,
  phone text,
  email text,
  service_type text,
  status text not null default 'Active',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- 6. CHINA PURCHASE ORDERS
-- ============================================================
create table if not exists public.cn_orders (
  id uuid primary key default gen_random_uuid(),
  order_id text not null unique default ('CN' || lpad(nextval('cn_order_seq')::text, 6, '0')),
  customer_id uuid not null references public.customers(id) on delete restrict,
  customer text,
  platform text,
  shop_name text,
  product_name text,
  product_url text,
  variant text,
  quantity integer not null default 1 check (quantity > 0),
  unit_price_cny numeric(14,2) not null default 0,
  cny_per_usd numeric(14,6) not null default 1,
  product_total_cny numeric(14,2) not null default 0,
  domestic_shipping_cny numeric(14,2) not null default 0,
  service_fee_pct numeric(8,3) not null default 0,
  service_fee_usd numeric(14,2) not null default 0,
  total_due_usd numeric(14,2) not null default 0,
  payment_status text not null default 'Unpaid',
  amount_paid_usd numeric(14,2) not null default 0,
  payment_method text,
  payment_ref text,
  paid_at timestamptz,
  payment_received_by text,
  supplier_order_no text,
  shipping_partner_id uuid references public.shipping_partners(id) on delete set null,
  partner_tracking_no text,
  status text not null default 'Order Processing',
  note text,
  created_by text,
  updated_by text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (payment_status in ('Unpaid','Partial','Paid','Refunded')),
  check (status in ('Order Processing','Purchased','Shipping to China WH','Inbound Origin','Outbound Origin','Arrive WH-KH','Inbound WH-KH','Complete Order','Refund Order'))
);

create table if not exists public.cn_order_history (
  id uuid primary key default gen_random_uuid(),
  cn_order_id uuid not null references public.cn_orders(id) on delete cascade,
  event text not null default 'status',
  status text,
  created_by text,
  note text,
  created_at timestamptz not null default now()
);

create table if not exists public.cn_order_images (
  id uuid primary key default gen_random_uuid(),
  cn_order_id uuid not null references public.cn_orders(id) on delete cascade,
  storage_path text not null,
  category text,
  created_by text,
  created_at timestamptz not null default now()
);

create table if not exists public.cn_order_parcels (
  id uuid primary key default gen_random_uuid(),
  cn_order_id uuid not null references public.cn_orders(id) on delete cascade,
  domestic_tracking text not null,
  courier text,
  created_by text,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 7. MASTER ORDERS / TK PACKAGES
-- ============================================================
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_no text not null unique default ('THN' || lpad(nextval('order_no_seq')::text, 6, '0')),
  customer_id uuid references public.customers(id) on delete set null,
  customer text,
  platform text,
  china_wh_code text,
  kh_branch_code text,
  customer_address_id uuid references public.customer_addresses(id) on delete set null,
  status text not null default 'New',
  date timestamptz not null default now(),
  created_by text,
  updated_by text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.packages (
  id uuid primary key default gen_random_uuid(),
  tk text not null unique default ('TK' || lpad(nextval('tk_seq')::text, 8, '0')),
  cn_order_id uuid references public.cn_orders(id) on delete set null,
  order_no text,
  customer_id uuid references public.customers(id) on delete set null,
  product_name text,
  cargo_type text,
  package_type text not null default 'small_package',
  size_class text,
  length_cm numeric(10,2),
  width_cm numeric(10,2),
  height_cm numeric(10,2),
  weight_kg numeric(12,3),
  pricing_method text,
  rate numeric(14,4),
  freight_fee numeric(14,2),
  paid_amount numeric(14,2) not null default 0,
  freight_overridden boolean not null default false,
  inbound_status text,
  inbound_at timestamptz,
  package_count integer not null default 1,
  status text not null default 'Inbound Origin',
  origin_wh_code text,
  dest_branch_code text,
  shipping_partner_id uuid references public.shipping_partners(id) on delete set null,
  partner_tracking_no text,
  exception text,
  note text,
  created_by text,
  updated_by text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.status_history (
  id uuid primary key default gen_random_uuid(),
  tk text not null,
  status text not null,
  remark text,
  created_by text,
  created_at timestamptz not null default now()
);

create table if not exists public.cargo_photos (
  id uuid primary key default gen_random_uuid(),
  package_id uuid references public.packages(id) on delete cascade,
  tk text not null,
  customer_id uuid references public.customers(id) on delete set null,
  order_no text,
  category text,
  storage_path text not null,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 8. AGENCY ARRIVAL / SORTING / DELIVERY
-- ============================================================
create table if not exists public.arrival (
  id uuid primary key default gen_random_uuid(),
  shipment_no text,
  port text,
  "arrivalDate" timestamptz,
  status text not null default 'Pending',
  note text,
  created_at timestamptz not null default now()
);

create table if not exists public.sorting_records (
  id uuid primary key default gen_random_uuid(),
  package_id uuid references public.packages(id) on delete set null,
  tk text not null unique,
  branch_code text,
  branch_name text,
  status text not null default 'Completed',
  notes text,
  sorted_by text,
  sorted_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.deliveries (
  id uuid primary key default gen_random_uuid(),
  delivery_no text unique,
  customer_id uuid references public.customers(id) on delete set null,
  customer text,
  phone text,
  address_id uuid references public.customer_addresses(id) on delete set null,
  address text,
  branch_code text,
  status text not null default 'Pending',
  requested_at timestamptz not null default now(),
  scheduled_at timestamptz,
  delivered_at timestamptz,
  driver text,
  note text,
  created_by text,
  updated_by text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.delivery_items (
  id uuid primary key default gen_random_uuid(),
  delivery_id uuid not null references public.deliveries(id) on delete cascade,
  tk text not null,
  fee_due numeric(14,2) not null default 0,
  created_at timestamptz not null default now(),
  unique(delivery_id, tk)
);

create table if not exists public.customer_transfer (
  id uuid primary key default gen_random_uuid(),
  tk text not null,
  from_customer_id uuid references public.customers(id) on delete set null,
  from_customer text,
  to_customer_id uuid references public.customers(id) on delete set null,
  to_customer text,
  reason text,
  approved_by text,
  "approvedBy" text,
  status text not null default 'Resolved',
  created_at timestamptz not null default now()
);

-- ============================================================
-- 10. FINANCE / SETTINGS / SLA / AUDIT
-- ============================================================
create table if not exists public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  type text not null,
  amount numeric(14,2) not null,
  currency text not null default 'USD',
  reference text,
  note text,
  created_by text,
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references public.customers(id) on delete cascade,
  user_id uuid references public.users(id) on delete cascade,
  title text not null,
  message text,
  kind text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_auth_user_id uuid references auth.users(id) on delete set null,
  actor_name text,
  action text not null,
  module text,
  target_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.system_settings (
  id integer primary key default 1 check (id = 1),
  company jsonb not null default '{}'::jsonb,
  shipping jsonb not null default '{}'::jsonb,
  label jsonb not null default '{}'::jsonb,
  updated_by uuid,
  updated_at timestamptz not null default now()
);

create table if not exists public.shipping_policies (
  id uuid primary key default gen_random_uuid(),
  policy_name text not null,
  effective_date date,
  pricing_method text,
  currency text default 'USD',
  size_rates jsonb not null default '{}'::jsonb,
  weight_rate numeric(14,4) not null default 0,
  cbm_rate numeric(14,4) not null default 0,
  minimum_freight numeric(14,2) not null default 0,
  delivery_fee numeric(14,2) not null default 0,
  branch_delivery_fee numeric(14,2) not null default 0,
  handling_fee numeric(14,2) not null default 0,
  cargo_rates jsonb not null default '{}'::jsonb,
  created_by text,
  created_at timestamptz not null default now()
);

create table if not exists public.sla_notification_settings (
  id text primary key,
  enabled boolean not null default true,
  updated_by text,
  updated_at timestamptz not null default now()
);

create table if not exists public.sla_notifications (
  id uuid primary key default gen_random_uuid(),
  dedupe_key text not null unique,
  tk text,
  kind text,
  level text,
  message text,
  delay_days integer,
  read_at timestamptz,
  resolved_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.sla_change_log (
  id uuid primary key default gen_random_uuid(),
  setting text not null,
  previous_value jsonb,
  new_value jsonb,
  changed_by text,
  changed_by_name text,
  changed_at timestamptz not null default now()
);

-- ============================================================
-- 11. INDEXES
-- ============================================================
create index if not exists customers_auth_user_idx on public.customers(auth_user_id);
create index if not exists customer_addresses_customer_idx on public.customer_addresses(customer_id);
create index if not exists cn_orders_customer_idx on public.cn_orders(customer_id);
create index if not exists cn_orders_status_idx on public.cn_orders(status);
create index if not exists cn_orders_updated_idx on public.cn_orders(updated_at desc);
create index if not exists cn_history_order_idx on public.cn_order_history(cn_order_id, created_at);
create index if not exists cn_parcels_order_idx on public.cn_order_parcels(cn_order_id, created_at);
create index if not exists packages_customer_idx on public.packages(customer_id);
create index if not exists packages_order_no_idx on public.packages(order_no);
create index if not exists packages_cn_order_idx on public.packages(cn_order_id);
create index if not exists packages_status_idx on public.packages(status);
create index if not exists status_history_tk_idx on public.status_history(tk, created_at);
create index if not exists cargo_photos_tk_idx on public.cargo_photos(tk);
create index if not exists wallet_customer_idx on public.wallet_transactions(customer_id, created_at desc);
create index if not exists warehouse_history_ref_idx on public.warehouse_history(entity_type, ref, created_at desc);
create index if not exists sorting_records_branch_idx on public.sorting_records(branch_code, sorted_at desc);
create index if not exists deliveries_customer_idx on public.deliveries(customer_id, requested_at desc);
create index if not exists sla_notifications_tk_idx on public.sla_notifications(tk, created_at desc);

-- ============================================================
-- 12. AUTH HELPERS
-- ============================================================
create or replace function public.is_authenticated()
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null;
$$;

create or replace function public.current_staff()
returns public.users language sql stable security definer set search_path = public as $$
  select u from public.users u
  where u.auth_user_id = auth.uid() and u.status = 'Active'
  limit 1;
$$;

create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.users u where u.auth_user_id = auth.uid() and u.status = 'Active');
$$;

create or replace function public.is_super_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists(
    select 1 from public.users u
    where u.auth_user_id = auth.uid()
      and u.status = 'Active'
      and lower(replace(u.role, '_', ' ')) in ('super admin','superadmin')
  );
$$;

create or replace function public.current_customer_id()
returns uuid language sql stable security definer set search_path = public as $$
  select c.id from public.customers c
  where c.auth_user_id = auth.uid() and c.status = 'active'
  limit 1;
$$;

create or replace function public.is_customer()
returns boolean language sql stable security definer set search_path = public as $$
  select public.current_customer_id() is not null;
$$;

create or replace function public.has_permission(p_key text)
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_super_admin() or exists(
    select 1
    from public.users u
    join public.roles r on r.name = u.role
    where u.auth_user_id = auth.uid()
      and u.status = 'Active'
      and r.status = 'Active'
      and p_key = any(r.permissions)
  );
$$;

-- ============================================================
-- 9. CUSTOMER SAFE VIEWS
-- ============================================================
create or replace view public.customer_orders
with (security_invoker = true) as
select
  o.id,
  o.order_no,
  o.customer_id,
  o.customer,
  o.platform,
  o.status,
  o.china_wh_code,
  o.kh_branch_code,
  o.customer_address_id,
  o.date,
  o.created_at,
  o.updated_at
from public.orders o
where o.customer_id = public.current_customer_id();

create or replace view public.customer_packages
with (security_invoker = true) as
select
  p.id,
  p.tk,
  p.order_no,
  p.customer_id,
  p.product_name,
  p.cargo_type,
  p.package_type,
  p.size_class,
  p.weight_kg,
  p.status,
  p.inbound_status,
  p.inbound_at,
  p.freight_fee,
  p.paid_amount,
  p.dest_branch_code,
  p.created_at,
  p.updated_at
from public.packages p
where p.customer_id = public.current_customer_id();

create or replace view public.customer_package_timeline
with (security_invoker = true) as
select
  h.id,
  h.tk,
  h.status,
  h.created_at as reached_at
from public.status_history h
join public.packages p on p.tk = h.tk
where p.customer_id = public.current_customer_id();

create or replace view public.customer_tracking_view
with (security_invoker = true) as
select
  p.id,
  p.tk,
  p.order_no,
  p.customer_id,
  p.status,
  p.inbound_status,
  p.inbound_at,
  p.dest_branch_code,
  p.created_at,
  p.updated_at,
  p.product_name
from public.packages p
where p.customer_id = public.current_customer_id();


-- ============================================================
-- 13. CUSTOMER SELF-SERVICE RPCS
-- ============================================================
create or replace function public.clear_must_change_password()
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.customers set must_change_password = false, updated_at = now() where auth_user_id = auth.uid();
  update public.users set must_change_password = false, updated_at = now() where auth_user_id = auth.uid();
end;
$$;

create or replace function public.customer_update_profile(p_name text, p_email text)
returns public.customers language plpgsql security definer set search_path = public as $$
declare r public.customers;
begin
  update public.customers
     set name = trim(p_name), email = nullif(trim(p_email), ''), updated_at = now()
   where id = public.current_customer_id()
   returning * into r;
  return r;
end;
$$;

create or replace function public.customer_set_avatar(p_url text)
returns public.customers language plpgsql security definer set search_path = public as $$
declare r public.customers;
begin
  update public.customers set avatar_url = p_url, updated_at = now()
   where id = public.current_customer_id()
   returning * into r;
  return r;
end;
$$;

-- ============================================================
-- 14. CUSTOMER WALLET / SHIPPING FEE RPCS
-- ============================================================
create or replace function public.customer_wallet()
returns jsonb language plpgsql security definer set search_path = public as $$
declare cid uuid := public.current_customer_id();
declare bal numeric(14,2);
declare tx jsonb;
begin
  if cid is null then return jsonb_build_object('balance',0,'transactions','[]'::jsonb); end if;
  select balance into bal from public.customers where id = cid;
  select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc),'[]'::jsonb)
    into tx
    from (
      select id,type,amount,currency,reference,note,created_by,created_at
      from public.wallet_transactions
      where customer_id = cid
      order by created_at desc
      limit 500
    ) x;
  return jsonb_build_object('balance',coalesce(bal,0),'transactions',tx);
end;
$$;

create or replace function public.customer_shipping_fees()
returns table(tk text, freight_fee numeric, paid_amount numeric)
language sql stable security definer set search_path = public as $$
  select p.tk, coalesce(p.freight_fee,0), coalesce(p.paid_amount,0)
  from public.packages p
  where p.customer_id = public.current_customer_id();
$$;

create or replace function public.pay_shipping_fee(p_tk text, p_method text default 'wallet')
returns jsonb language plpgsql security definer set search_path = public as $$
declare cid uuid := public.current_customer_id();
declare p public.packages;
declare due numeric(14,2);
declare bal numeric(14,2);
begin
  if cid is null then raise exception 'Customer session required'; end if;
  if lower(coalesce(p_method,'wallet')) <> 'wallet' then raise exception 'Only wallet payment is supported'; end if;
  select * into p from public.packages where tk = p_tk and customer_id = cid for update;
  if not found then raise exception 'Package not found'; end if;
  due := greatest(coalesce(p.freight_fee,0) - coalesce(p.paid_amount,0), 0);
  if due <= 0 then return jsonb_build_object('ok',true,'due',0); end if;
  select balance into bal from public.customers where id = cid for update;
  if coalesce(bal,0) < due then raise exception 'Insufficient wallet balance'; end if;
  update public.customers set balance = balance - due, updated_at = now() where id = cid;
  update public.packages set paid_amount = coalesce(paid_amount,0) + due, updated_at = now() where id = p.id;
  insert into public.wallet_transactions(customer_id,type,amount,currency,reference,note,created_by)
  values(cid,'shipping_payment_wallet',-due,'USD',p_tk,'Shipping fee payment',cid::text);
  return jsonb_build_object('ok',true,'tk',p_tk,'paid',due,'due',0);
end;
$$;

create or replace function public.wallet_top_up(p_customer_id uuid, p_amount numeric, p_note text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public.is_super_admin() and not public.has_permission('cn_order.payment') then raise exception 'Permission denied'; end if;
  if p_amount <= 0 then raise exception 'Amount must be greater than zero'; end if;
  update public.customers set balance = balance + p_amount, updated_at = now() where id = p_customer_id;
  if not found then raise exception 'Customer not found'; end if;
  insert into public.wallet_transactions(customer_id,type,amount,currency,note,created_by)
  values(p_customer_id,'top_up',p_amount,'USD',p_note,coalesce((select name from public.users where auth_user_id=auth.uid()),'Admin'));
  return jsonb_build_object('ok',true,'amount',p_amount);
end;
$$;

create or replace function public.wallet_reverse_top_up(
  p_tx_id uuid,
  p_reason text,
  p_by text,
  p_amount numeric,
  p_allow_negative boolean default false
)
returns jsonb language plpgsql security definer set search_path = public as $$
declare tx public.wallet_transactions;
declare remaining numeric;
declare bal numeric;
begin
  if not public.is_super_admin() and not public.has_permission('cn_order.payment') then raise exception 'Permission denied'; end if;
  select * into tx from public.wallet_transactions where id = p_tx_id and type = 'top_up' for update;
  if not found then raise exception 'Top up transaction not found'; end if;
  if p_amount <= 0 then raise exception 'Amount must be greater than zero'; end if;
  if p_amount > tx.amount then raise exception 'Amount exceeds top up'; end if;
  select balance into bal from public.customers where id = tx.customer_id for update;
  if not p_allow_negative and coalesce(bal,0) < p_amount then raise exception 'Balance is not enough'; end if;
  update public.customers set balance = balance - p_amount, updated_at = now() where id = tx.customer_id;
  insert into public.wallet_transactions(customer_id,type,amount,currency,reference,note,created_by)
  values(tx.customer_id,'top_up_reversal',-p_amount,'USD',tx.id::text,p_reason,p_by);
  remaining := tx.amount - p_amount;
  return jsonb_build_object('ok',true,'remaining_reversible',remaining);
end;
$$;

-- ============================================================
-- 15. CHINA ORDER/TK SYNC
-- ============================================================
create or replace function public.sync_cn_order_from_tk()
returns trigger language plpgsql security definer set search_path = public as $$
declare target text;
begin
  target := case new.status
    when 'Inbound Origin' then 'Inbound Origin'
    when 'Outbound Origin' then 'Outbound Origin'
    when 'Arrived Destination' then 'Arrive WH-KH'
    when 'Shipping To Branch' then 'Arrive WH-KH'
    when 'Inbound Warehouse' then 'Inbound WH-KH'
    when 'Completed' then 'Complete Order'
    else null
  end;
  if target is not null and new.cn_order_id is not null then
    update public.cn_orders
       set status = target,
           updated_by = coalesce(new.updated_by,new.created_by),
           updated_at = now()
     where id = new.cn_order_id;
  end if;
  return new;
end;
$$;

drop trigger if exists packages_sync_cn_order on public.packages;
create trigger packages_sync_cn_order
after insert or update of status, cn_order_id on public.packages
for each row execute function public.sync_cn_order_from_tk();

create or replace function public.log_package_status()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' or new.status is distinct from old.status then
    insert into public.status_history(tk,status,remark,created_by)
    values(new.tk,new.status,case when tg_op='INSERT' then 'Package created' else 'Status updated' end,coalesce(new.updated_by,new.created_by,'System'));
  end if;
  return new;
end;
$$;

drop trigger if exists packages_status_history on public.packages;
create trigger packages_status_history
after insert or update of status on public.packages
for each row execute function public.log_package_status();

-- ============================================================
-- 16. UPDATED-AT TRIGGERS
-- ============================================================
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

do $$
declare t text;
begin
  foreach t in array array[
    'roles','users','customers','customer_addresses','customer_china_warehouse',
    'customer_roles','customer_features','warehouses','shipping_partners',
    'cn_orders','orders','packages','deliveries','system_settings'
  ] loop
    execute format('drop trigger if exists %I_set_updated_at on public.%I', t,t);
    execute format('create trigger %I_set_updated_at before update on public.%I for each row execute function public.set_updated_at()',t,t);
  end loop;
end $$;

-- ============================================================
-- 17. RLS
-- ============================================================
alter table public.roles enable row level security;
alter table public.users enable row level security;
alter table public.customers enable row level security;
alter table public.customer_addresses enable row level security;
alter table public.customer_china_warehouse enable row level security;
alter table public.customer_roles enable row level security;
alter table public.customer_features enable row level security;
alter table public.warehouses enable row level security;
alter table public.warehouse_history enable row level security;
alter table public.shipping_partners enable row level security;
alter table public.cn_orders enable row level security;
alter table public.cn_order_history enable row level security;
alter table public.cn_order_images enable row level security;
alter table public.cn_order_parcels enable row level security;
alter table public.orders enable row level security;
alter table public.packages enable row level security;
alter table public.status_history enable row level security;
alter table public.cargo_photos enable row level security;
alter table public.arrival enable row level security;
alter table public.sorting_records enable row level security;
alter table public.deliveries enable row level security;
alter table public.delivery_items enable row level security;
alter table public.customer_transfer enable row level security;
alter table public.wallet_transactions enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_logs enable row level security;
alter table public.system_settings enable row level security;
alter table public.shipping_policies enable row level security;
alter table public.sla_notification_settings enable row level security;
alter table public.sla_notifications enable row level security;
alter table public.sla_change_log enable row level security;

-- Drop/recreate policies so this script can safely be re-run.
do $$
declare r record;
begin
  for r in select schemaname, tablename, policyname from pg_policies where schemaname='public' loop
    execute format('drop policy if exists %I on public.%I',r.policyname,r.tablename);
  end loop;
end $$;

-- Staff tables
create policy users_select on public.users for select to authenticated using (public.is_staff() or auth_user_id=auth.uid());
create policy users_insert on public.users for insert to authenticated with check (public.has_permission('user.create') or public.is_super_admin());
create policy users_update on public.users for update to authenticated using (public.has_permission('user.edit') or public.is_super_admin()) with check (public.has_permission('user.edit') or public.is_super_admin());
create policy users_delete on public.users for delete to authenticated using (public.has_permission('user.delete') or public.is_super_admin());

create policy roles_select on public.roles for select to authenticated using (public.is_staff());
create policy roles_manage on public.roles for all to authenticated using (public.has_permission('role.edit') or public.is_super_admin()) with check (public.has_permission('role.edit') or public.is_super_admin());

create policy customer_select on public.customers for select to authenticated using (public.is_staff() or id=public.current_customer_id());
create policy customer_insert on public.customers for insert to authenticated with check (public.has_permission('customer.create') or public.is_super_admin());
create policy customer_update on public.customers for update to authenticated using (public.has_permission('customer.edit') or public.is_super_admin() or id=public.current_customer_id()) with check (public.has_permission('customer.edit') or public.is_super_admin() or id=public.current_customer_id());
create policy customer_delete on public.customers for delete to authenticated using (public.has_permission('customer.delete') or public.is_super_admin());

create policy address_select on public.customer_addresses for select to authenticated using (public.is_staff() or customer_id=public.current_customer_id());
create policy address_insert on public.customer_addresses for insert to authenticated with check (public.has_permission('customer_address.create') or customer_id=public.current_customer_id());
create policy address_update on public.customer_addresses for update to authenticated using (public.has_permission('customer.edit') or customer_id=public.current_customer_id()) with check (public.has_permission('customer.edit') or customer_id=public.current_customer_id());
create policy address_delete on public.customer_addresses for delete to authenticated using (public.has_permission('customer.edit') or customer_id=public.current_customer_id());

create policy china_wh_select on public.customer_china_warehouse for select to authenticated using (public.is_staff() or customer_id=public.current_customer_id());
create policy china_wh_manage on public.customer_china_warehouse for all to authenticated using (public.has_permission('customer.edit') or customer_id=public.current_customer_id()) with check (public.has_permission('customer.edit') or customer_id=public.current_customer_id());

create policy customer_role_select on public.customer_roles for select to authenticated using (public.is_staff());
create policy customer_role_manage on public.customer_roles for all to authenticated using (public.is_super_admin() or public.has_permission('role.edit')) with check (public.is_super_admin() or public.has_permission('role.edit'));
create policy customer_feature_select on public.customer_features for select to authenticated using (public.is_staff());
create policy customer_feature_manage on public.customer_features for all to authenticated using (public.is_super_admin() or public.has_permission('role.edit')) with check (public.is_super_admin() or public.has_permission('role.edit'));

create policy warehouse_select on public.warehouses for select to authenticated using (public.is_staff() or public.is_customer());
create policy warehouse_manage on public.warehouses for all to authenticated using (public.has_permission('warehouse.manage') or public.is_super_admin()) with check (public.has_permission('warehouse.manage') or public.is_super_admin());
create policy warehouse_history_select on public.warehouse_history for select to authenticated using (public.is_staff());
create policy warehouse_history_insert on public.warehouse_history for insert to authenticated with check (public.is_staff());

create policy partner_select on public.shipping_partners for select to authenticated using (public.is_staff());
create policy partner_manage on public.shipping_partners for all to authenticated using (public.has_permission('shipping_partner.manage') or public.is_super_admin()) with check (public.has_permission('shipping_partner.manage') or public.is_super_admin());

-- Orders / packages
create policy cn_order_select on public.cn_orders for select to authenticated using (public.is_staff() or customer_id=public.current_customer_id());
create policy cn_order_insert on public.cn_orders for insert to authenticated with check (public.has_permission('cn_order.create') or public.is_super_admin());
create policy cn_order_update on public.cn_orders for update to authenticated using (public.has_permission('cn_order.edit') or public.is_super_admin()) with check (public.has_permission('cn_order.edit') or public.is_super_admin());
create policy cn_order_delete on public.cn_orders for delete to authenticated using (public.has_permission('cn_order.delete') or public.is_super_admin());

create policy cn_history_select on public.cn_order_history for select to authenticated using (public.is_staff() or exists(select 1 from public.cn_orders o where o.id=cn_order_id and o.customer_id=public.current_customer_id()));
create policy cn_history_insert on public.cn_order_history for insert to authenticated with check (public.is_staff());
create policy cn_images_select on public.cn_order_images for select to authenticated using (public.is_staff() or exists(select 1 from public.cn_orders o where o.id=cn_order_id and o.customer_id=public.current_customer_id()));
create policy cn_images_manage on public.cn_order_images for all to authenticated using (public.has_permission('cn_order.edit') or public.is_super_admin()) with check (public.has_permission('cn_order.edit') or public.is_super_admin());
create policy cn_parcel_select on public.cn_order_parcels for select to authenticated using (public.is_staff() or exists(select 1 from public.cn_orders o where o.id=cn_order_id and o.customer_id=public.current_customer_id()));
create policy cn_parcel_manage on public.cn_order_parcels for all to authenticated using (public.has_permission('cn_order.process') or public.is_super_admin()) with check (public.has_permission('cn_order.process') or public.is_super_admin());

create policy order_select on public.orders for select to authenticated using (public.is_staff() or customer_id=public.current_customer_id());
create policy order_manage on public.orders for all to authenticated using (public.has_permission('order.edit') or public.is_super_admin()) with check (public.has_permission('order.edit') or public.is_super_admin());

create policy package_select on public.packages for select to authenticated using (public.is_staff() or customer_id=public.current_customer_id());
create policy package_insert on public.packages for insert to authenticated with check (public.has_permission('tk.create') or public.is_super_admin());
create policy package_update on public.packages for update to authenticated using (public.has_permission('tk.edit') or public.has_permission('tk.process') or public.is_super_admin()) with check (public.has_permission('tk.edit') or public.has_permission('tk.process') or public.is_super_admin());
create policy package_delete on public.packages for delete to authenticated using (public.has_permission('tk.delete') or public.is_super_admin());

create policy status_select on public.status_history for select to authenticated using (public.is_staff() or exists(select 1 from public.packages p where p.tk=status_history.tk and p.customer_id=public.current_customer_id()));
create policy status_insert on public.status_history for insert to authenticated with check (public.is_staff());
create policy cargo_select on public.cargo_photos for select to authenticated using (public.is_staff() or customer_id=public.current_customer_id());
create policy cargo_insert on public.cargo_photos for insert to authenticated with check (public.has_permission('tk.create') or public.has_permission('tk.edit') or public.is_super_admin());
create policy cargo_delete on public.cargo_photos for delete to authenticated using (public.has_permission('tk.edit') or public.is_super_admin());

create policy arrival_select on public.arrival for select to authenticated using (public.is_staff());
create policy arrival_manage on public.arrival for all to authenticated using (public.has_permission('arrival.view') or public.is_super_admin()) with check (public.has_permission('arrival.view') or public.is_super_admin());
create policy sorting_select on public.sorting_records for select to authenticated using (public.is_staff());
create policy sorting_manage on public.sorting_records for all to authenticated using (public.has_permission('sorting.process') or public.is_super_admin()) with check (public.has_permission('sorting.process') or public.is_super_admin());
create policy delivery_select on public.deliveries for select to authenticated using (public.is_staff() or customer_id=public.current_customer_id());
create policy delivery_manage on public.deliveries for all to authenticated using (public.has_permission('delivery.create') or public.is_super_admin()) with check (public.has_permission('delivery.create') or public.is_super_admin());
create policy delivery_item_select on public.delivery_items for select to authenticated using (public.is_staff() or exists(select 1 from public.deliveries d where d.id=delivery_id and d.customer_id=public.current_customer_id()));
create policy delivery_item_manage on public.delivery_items for all to authenticated using (public.has_permission('delivery.create') or public.is_super_admin()) with check (public.has_permission('delivery.create') or public.is_super_admin());

create policy transfer_select on public.customer_transfer for select to authenticated using (public.is_staff() or from_customer_id=public.current_customer_id() or to_customer_id=public.current_customer_id());
create policy transfer_insert on public.customer_transfer for insert to authenticated with check (public.has_permission('customer_transfer.view') or public.is_super_admin());

-- Finance / settings / SLA
create policy wallet_select on public.wallet_transactions for select to authenticated using (customer_id=public.current_customer_id() or public.has_permission('cn_order.payment') or public.is_super_admin());
create policy wallet_insert on public.wallet_transactions for insert to authenticated with check (public.has_permission('cn_order.payment') or public.is_super_admin());
create policy notification_select on public.notifications for select to authenticated using (customer_id=public.current_customer_id() or exists(select 1 from public.users u where u.id=notifications.user_id and u.auth_user_id=auth.uid()) or public.is_staff());
create policy notification_manage on public.notifications for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy audit_select on public.audit_logs for select to authenticated using (public.is_super_admin() or public.has_permission('audit.view'));
create policy audit_insert on public.audit_logs for insert to authenticated with check (public.is_staff());
create policy settings_select on public.system_settings for select to authenticated using (public.is_staff());
create policy settings_manage on public.system_settings for all to authenticated using (public.is_super_admin() or public.has_permission('settings.edit')) with check (public.is_super_admin() or public.has_permission('settings.edit'));
create policy shipping_policy_select on public.shipping_policies for select to authenticated using (public.is_staff());
create policy shipping_policy_manage on public.shipping_policies for all to authenticated using (public.is_super_admin() or public.has_permission('settings.edit')) with check (public.is_super_admin() or public.has_permission('settings.edit'));
create policy sla_setting_select on public.sla_notification_settings for select to authenticated using (public.is_staff());
create policy sla_setting_manage on public.sla_notification_settings for all to authenticated using (public.is_super_admin() or public.has_permission('settings.edit')) with check (public.is_super_admin() or public.has_permission('settings.edit'));
create policy sla_select on public.sla_notifications for select to authenticated using (public.is_staff());
create policy sla_manage on public.sla_notifications for all to authenticated using (public.is_staff()) with check (public.is_staff());
create policy sla_log_select on public.sla_change_log for select to authenticated using (public.is_super_admin() or public.has_permission('audit.view'));
create policy sla_log_insert on public.sla_change_log for insert to authenticated with check (public.is_staff());

-- ============================================================
-- 18. STORAGE
-- ============================================================
insert into storage.buckets(id,name,public)
values
 ('cargo-photos','cargo-photos',true),
 ('cn-order-images','cn-order-images',true),
 ('avatars','avatars',true),
 ('company-assets','company-assets',true)
on conflict (id) do nothing;

drop policy if exists cargo_photos_public_read on storage.objects;
create policy cargo_photos_public_read on storage.objects for select to public
using (bucket_id in ('cargo-photos','cn-order-images','avatars','company-assets'));

drop policy if exists cargo_photos_staff_insert on storage.objects;
create policy cargo_photos_staff_insert on storage.objects for insert to authenticated
with check (bucket_id='cargo-photos' and (public.has_permission('tk.create') or public.has_permission('tk.edit') or public.is_super_admin()));

drop policy if exists cn_order_images_staff_insert on storage.objects;
create policy cn_order_images_staff_insert on storage.objects for insert to authenticated
with check (bucket_id='cn-order-images' and (public.has_permission('cn_order.create') or public.has_permission('cn_order.edit') or public.is_super_admin()));

drop policy if exists avatars_owner_insert on storage.objects;
create policy avatars_owner_insert on storage.objects for insert to authenticated
with check (bucket_id='avatars' and name like auth.uid()::text || '/%');
drop policy if exists avatars_owner_update on storage.objects;
create policy avatars_owner_update on storage.objects for update to authenticated
using (bucket_id='avatars' and name like auth.uid()::text || '/%')
with check (bucket_id='avatars' and name like auth.uid()::text || '/%');
drop policy if exists avatars_owner_delete on storage.objects;
create policy avatars_owner_delete on storage.objects for delete to authenticated
using (bucket_id='avatars' and name like auth.uid()::text || '/%');

drop policy if exists company_assets_staff_write on storage.objects;
create policy company_assets_staff_write on storage.objects for all to authenticated
using (bucket_id='company-assets' and (public.is_super_admin() or public.has_permission('settings.edit')))
with check (bucket_id='company-assets' and (public.is_super_admin() or public.has_permission('settings.edit')));

-- ============================================================
-- 19. DEFAULT ROLES / FEATURES / SLA
-- ============================================================
insert into public.roles(name,level,scope,status,description,is_system,permissions) values
('Super Admin',0,'GLOBAL','Active','Full China system access.',true,ARRAY[
'dashboard.view','dashboard.china','lookup.view','cn_order.view','cn_order.create','cn_order.edit','cn_order.payment','cn_order.purchase','cn_order.process','cn_order.refund','cn_order.delete',
'tk.view','tk.create','tk.edit','tk.delete','tk.scan','tk.manage_inbound','tk.process','tk.remeasure','tk.freight_override',
'customer.view','customer.create','customer.edit','customer.delete','customer.reset_password','customer_account.view','customer_account.create','customer_address.view','customer_address.create','customer_transfer.view',
'order.view','order.edit','order.delete','order.change_branch','user.view','user.create','user.edit','user.delete','role.view','role.edit',
'warehouse.view','warehouse.manage','shipping_partner.manage','arrival.view','sorting.view','sorting.scan','sorting.process','delivery.view','delivery.create','audit.view','settings.view','settings.edit','report.view','exception.view','exception.edit','notification.view','notification.edit','customer_transfer.view'
])
('Manager',1,'DEPARTMENT','Active','China department manager.',false,ARRAY[
'dashboard.view','dashboard.china','lookup.view','cn_order.view','cn_order.create','cn_order.edit','cn_order.payment','cn_order.purchase','cn_order.process','cn_order.refund',
'tk.view','tk.create','tk.edit','tk.scan','tk.manage_inbound','tk.process','tk.remeasure','customer.view','customer.create','customer.edit','customer.reset_password','customer_address.view','customer_address.create',
'order.view','order.edit','order.change_branch','user.view','user.create','user.edit','role.view','warehouse.view','warehouse.manage','shipping_partner.manage','arrival.view','sorting.view','sorting.scan','sorting.process','delivery.view','delivery.create','settings.view','report.view','exception.view','notification.view','customer_transfer.view'
]),
('Supervisor',2,'DEPARTMENT','Active','China team supervisor.',false,ARRAY[
'dashboard.view','dashboard.china','lookup.view','cn_order.view','cn_order.create','cn_order.edit','cn_order.payment','cn_order.purchase','cn_order.process','cn_order.refund',
'tk.view','tk.create','tk.edit','tk.scan','tk.manage_inbound','tk.process','tk.remeasure','customer.view','customer.create','customer.edit','customer.reset_password','customer_address.view','customer_address.create',
'order.view','order.edit','warehouse.view','shipping_partner.manage','arrival.view','sorting.view','sorting.scan','sorting.process','delivery.view','customer_transfer.view'
]),
('Senior Officer',3,'WAREHOUSE','Active','Experienced China warehouse operator.',false,ARRAY[
'dashboard.view','dashboard.china','lookup.view','cn_order.view','cn_order.process','tk.view','tk.create','tk.edit','tk.scan','tk.manage_inbound','tk.process','tk.remeasure','customer.view','customer_address.view','order.view','warehouse.view','arrival.view','sorting.view','sorting.scan','sorting.process','delivery.view'
]),
('Officer',4,'WAREHOUSE','Active','China warehouse officer.',false,ARRAY[
'dashboard.view','dashboard.china','lookup.view','cn_order.view','cn_order.process','tk.view','tk.create','tk.scan','tk.manage_inbound','customer.view','customer_address.view','order.view','warehouse.view','arrival.view','sorting.view','sorting.scan','delivery.view'
])
on conflict(name) do update set permissions=excluded.permissions, level=excluded.level, scope=excluded.scope, status=excluded.status;

insert into public.customer_roles(name,description,status) values
('Customer','Standard China customer','Active') on conflict(name) do nothing;
insert into public.customer_features(key,label,enabled) values
('orders','China Orders',true),('tracking','TK Tracking',true),('wallet','Wallet',true),('addresses','Receiving Addresses',true),('china_warehouse','China Warehouse Address',true),('delivery','Delivery',true)
on conflict(key) do nothing;

insert into public.sla_notification_settings(id,enabled) values
('inbound_origin',true),('outbound_origin',true),('arrive_wh_kh',true),('inbound_wh_kh',true),('complete_order',true)
on conflict(id) do nothing;

-- ============================================================
-- END
-- ============================================================
-- IMPORTANT:
-- 1. Create the first Super Admin in Supabase Auth.
-- 2. Insert a matching public.users row with role='Super Admin'.
-- 3. Deploy the China app with this Supabase URL/key.
-- 4. Password reset is handled by supabase/functions/reset-password/index.ts.
-- 5. There are intentionally NO AIR tables and NO Container tables/functions here.
-- ============================================================
