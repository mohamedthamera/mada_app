-- Lifetime subscription system: tables, RLS, indexes, RPC
create extension if not exists pgcrypto;

create table if not exists public.user_subscriptions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  is_lifetime boolean not null default false,
  source text check (source in ('code','gateway')) null,
  activated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.lifetime_codes (
  code text primary key,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  expires_at timestamptz,
  max_redemptions integer not null default 1,
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists public.lifetime_code_redemptions (
  id uuid primary key default gen_random_uuid(),
  code text not null references public.lifetime_codes(code) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  redeemed_at timestamptz not null default now(),
  unique (code, user_id)
);

create index if not exists idx_lifetime_redemptions_code on public.lifetime_code_redemptions(code);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null,
  amount numeric(12,2) not null,
  currency text not null,
  status text not null check (status in ('pending','paid','failed','canceled')),
  provider_ref text not null,
  raw_payload jsonb,
  created_at timestamptz not null default now(),
  verified_at timestamptz,
  unique (provider_ref)
);

alter table public.user_subscriptions enable row level security;
alter table public.lifetime_codes enable row level security;
alter table public.lifetime_code_redemptions enable row level security;
alter table public.payments enable row level security;

drop policy if exists user_subscriptions_select_own on public.user_subscriptions;
create policy user_subscriptions_select_own
  on public.user_subscriptions
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists payments_select_own on public.payments;
create policy payments_select_own
  on public.payments
  for select
  to authenticated
  using (user_id = auth.uid());

-- No other policies are created, so inserts/updates/deletes are blocked for non-service roles

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists user_subscriptions_set_updated_at on public.user_subscriptions;
create trigger user_subscriptions_set_updated_at
before update on public.user_subscriptions
for each row
execute function public.set_updated_at();

create or replace function public.redeem_lifetime_code(p_code text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_code record;
  v_count integer;
  v_already boolean;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  select *
  into v_code
  from public.lifetime_codes
  where code = p_code
  for update;

  if not found then
    raise exception 'invalid_code';
  end if;

  if v_code.expires_at is not null and v_code.expires_at < now() then
    raise exception 'expired_code';
  end if;

  select exists(
    select 1 from public.lifetime_code_redemptions
    where code = p_code and user_id = v_uid
  ) into v_already;

  if v_already then
    raise exception 'already_redeemed';
  end if;

  select count(*) from public.lifetime_code_redemptions where code = p_code into v_count;
  if v_count >= v_code.max_redemptions then
    raise exception 'code_exhausted';
  end if;

  insert into public.lifetime_code_redemptions(code, user_id) values (p_code, v_uid);

  insert into public.user_subscriptions(user_id, is_lifetime, source, activated_at)
  values (v_uid, true, 'code', now())
  on conflict (user_id) do update
    set is_lifetime = true,
        source = 'code',
        activated_at = excluded.activated_at,
        updated_at = now();

  return true;
end;
$$;

revoke all on function public.redeem_lifetime_code(text) from public;
grant execute on function public.redeem_lifetime_code(text) to authenticated;

