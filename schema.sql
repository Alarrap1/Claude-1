-- ======================================================
-- CRM Database Schema (Supabase / Postgres)
-- Tables: users, leads, activities
-- ======================================================

create extension if not exists "pgcrypto";

-- ===================== USERS =====================
create table if not exists public.users (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  role text not null check (role in ('tele', 'sales', 'manager')),
  password text not null
);

-- ===================== LEADS =====================
create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  source text,
  assigned_tele text,
  assigned_sales text,
  stage text not null default 'new'
    check (stage in ('new', 'contacted', 'qualified', 'meeting', 'won', 'lost')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_leads_assigned_tele on public.leads (assigned_tele);
create index if not exists idx_leads_assigned_sales on public.leads (assigned_sales);
create index if not exists idx_leads_stage on public.leads (stage);

-- ===================== ACTIVITIES =====================
create table if not exists public.activities (
  id uuid primary key default gen_random_uuid(),
  lead_id uuid not null references public.leads (id) on delete cascade,
  "user" text,
  action text not null,
  note text,
  timestamp timestamptz not null default now()
);

create index if not exists idx_activities_lead_id on public.activities (lead_id);

-- ======================================================
-- Row Level Security
-- App authenticates with a custom users table (not Supabase Auth),
-- and uses the publishable/anon key client-side, so RLS must allow
-- the operations the app needs while the anon key is exposed in
-- the browser. Tighten further if you add Supabase Auth later.
-- ======================================================

alter table public.users enable row level security;
alter table public.leads enable row level security;
alter table public.activities enable row level security;

create policy "users_select_all" on public.users
  for select using (true);

create policy "leads_select_all" on public.leads
  for select using (true);
create policy "leads_insert_all" on public.leads
  for insert with check (true);
create policy "leads_update_all" on public.leads
  for update using (true);

create policy "activities_select_all" on public.activities
  for select using (true);
create policy "activities_insert_all" on public.activities
  for insert with check (true);

-- ======================================================
-- Seed example users (replace with your real team + passwords)
-- ======================================================
insert into public.users (name, role, password) values
  ('Manager', 'manager', 'changeme'),
  ('Tele1', 'tele', 'changeme'),
  ('Sales1', 'sales', 'changeme')
on conflict (name) do nothing;
