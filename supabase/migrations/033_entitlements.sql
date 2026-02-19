-- Entitlements table for IAP-based lifetime access (Apple IAP / Google Play Billing).
-- RLS: users can SELECT their own row; INSERT/UPDATE only via service role (Edge Function).

create table if not exists public.entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  lifetime_access boolean not null default false,
  platform text check (platform in ('ios','android')),
  product_id text,
  ios_original_transaction_id text unique,
  ios_latest_transaction_id text,
  android_purchase_token text unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_entitlements_lifetime on public.entitlements(lifetime_access) where lifetime_access = true;
create index if not exists idx_entitlements_ios_original on public.entitlements(ios_original_transaction_id) where ios_original_transaction_id is not null;
create index if not exists idx_entitlements_android_token on public.entitlements(android_purchase_token) where android_purchase_token is not null;

alter table public.entitlements enable row level security;

-- Users can only SELECT their own entitlement row.
drop policy if exists entitlements_select_own on public.entitlements;
create policy entitlements_select_own
  on public.entitlements
  for select
  to authenticated
  using (user_id = auth.uid());

-- No INSERT/UPDATE/DELETE for authenticated; only service role (Edge Function) can write.

-- Auto-update updated_at on row change (reuse existing function from 021 if present).
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists entitlements_set_updated_at on public.entitlements;
create trigger entitlements_set_updated_at
  before update on public.entitlements
  for each row
  execute function public.set_updated_at();

-- If table already existed without created_at, add the column (idempotent for new installs).
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'entitlements' and column_name = 'created_at'
  ) then
    alter table public.entitlements add column created_at timestamptz not null default now();
  end if;
end $$;

comment on table public.entitlements is 'IAP-verified lifetime access; written only by verify_lifetime_purchase Edge Function.';
