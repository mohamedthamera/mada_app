-- Referral / Influencer codes: tracking only (no payments)
-- One code per user, immutable once set. Codes never expire unless admin disables.

-- A) influencers
create table if not exists public.influencers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text unique not null,
  is_active boolean not null default true,
  deleted_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_influencers_code on public.influencers (code);
create index if not exists idx_influencers_is_active on public.influencers (is_active) where deleted_at is null;

-- B) user_referrals (one row per user, set once)
create table if not exists public.user_referrals (
  user_id uuid primary key references auth.users(id) on delete cascade,
  influencer_id uuid not null references public.influencers(id),
  code_used text not null,
  referred_at timestamptz not null default now()
);

create index if not exists idx_user_referrals_influencer on public.user_referrals (influencer_id);

-- C) influencer_stats view (for analytics / admin)
create or replace view public.influencer_stats as
select
  i.id as influencer_id,
  i.name as influencer_name,
  i.code as referral_code,
  i.is_active,
  i.created_at,
  coalesce(r.total_users, 0)::bigint as total_users
from public.influencers i
left join (
  select influencer_id, count(*) as total_users
  from public.user_referrals
  group by influencer_id
) r on r.influencer_id = i.id
where i.deleted_at is null;

-- RLS: influencers
alter table public.influencers enable row level security;

-- Public: SELECT only active, non-deleted (code + name for validation/display)
create policy "influencers_select_active"
  on public.influencers for select
  using (is_active = true and deleted_at is null);

-- No INSERT/UPDATE/DELETE for anon/authenticated (admin via service role / Edge Function)
-- So we don't create any write policies for normal users.

-- RLS: user_referrals
alter table public.user_referrals enable row level security;

-- User can INSERT only for themselves (user_id = auth.uid()) — enforced in RPC, policy allows it
create policy "user_referrals_insert_own"
  on public.user_referrals for insert
  with check (auth.uid() = user_id);

-- User can SELECT only their own row
create policy "user_referrals_select_own"
  on public.user_referrals for select
  using (auth.uid() = user_id);

-- No UPDATE/DELETE policies: referral is immutable once set

-- RPC: apply_referral_code(p_code text) returns json
create or replace function public.apply_referral_code(p_code text)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_influencer record;
  v_exists boolean;
begin
  if v_uid is null then
    return json_build_object('ok', false, 'error', 'not authenticated');
  end if;

  -- Already has a referral?
  select exists(
    select 1 from public.user_referrals where user_id = v_uid
  ) into v_exists;
  if v_exists then
    return json_build_object('ok', false, 'error', 'Referral already set');
  end if;

  -- Trim and validate code
  p_code := trim(upper(coalesce(p_code, '')));
  if p_code = '' then
    return json_build_object('ok', false, 'error', 'Invalid code');
  end if;

  -- Code exists and is active (and not soft-deleted)
  select id, name, code into v_influencer
  from public.influencers
  where upper(trim(code)) = p_code
    and is_active = true
    and deleted_at is null;
  if v_influencer.id is null then
    return json_build_object('ok', false, 'error', 'Invalid or inactive code');
  end if;

  insert into public.user_referrals (user_id, influencer_id, code_used)
  values (v_uid, v_influencer.id, v_influencer.code);

  return json_build_object('ok', true, 'influencer_name', v_influencer.name);
end;
$$;

-- Grant execute to authenticated users
grant execute on function public.apply_referral_code(text) to authenticated;
grant execute on function public.apply_referral_code(text) to service_role;
