-- جهاز واحد لكل حساب: عند فتح الحساب من جهاز آخر يتم حظر الحساب بالكامل

-- أعمدة ربط الجهاز والحظر في profiles
alter table public.profiles
  add column if not exists allowed_device_id text;

alter table public.profiles
  add column if not exists banned_at timestamptz;

alter table public.profiles
  add column if not exists ban_reason text;

comment on column public.profiles.allowed_device_id is 'معرّف الجهاز المسموح به فقط (أول جهاز يسجّل الدخول)';
comment on column public.profiles.banned_at is 'تاريخ الحظر (إن وُجد)';
comment on column public.profiles.ban_reason is 'سبب الحظر مثلاً: multiple_devices';

-- RPC: التحقق من الجهاز أو تسجيله. إن كان المستخدم محظوراً أو فتح من جهاز آخر يُحظر ويُرجع banned.
create or replace function public.check_device_or_register(p_device_id text)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_profile record;
begin
  if v_uid is null then
    return json_build_object('allowed', false, 'banned', false, 'error', 'not authenticated');
  end if;

  p_device_id := trim(coalesce(p_device_id, ''));
  if p_device_id = '' then
    return json_build_object('allowed', false, 'banned', false, 'error', 'device_id required');
  end if;

  select allowed_device_id, banned_at, ban_reason
  into v_profile
  from public.profiles
  where id = v_uid;

  if v_profile.banned_at is not null then
    return json_build_object('allowed', false, 'banned', true);
  end if;

  if v_profile.allowed_device_id is null then
    update public.profiles
    set allowed_device_id = p_device_id
    where id = v_uid;
    return json_build_object('allowed', true, 'banned', false);
  end if;

  if v_profile.allowed_device_id = p_device_id then
    return json_build_object('allowed', true, 'banned', false);
  end if;

  -- جهاز مختلف: حظر الحساب
  update public.profiles
  set banned_at = now(),
      ban_reason = 'multiple_devices'
  where id = v_uid;

  return json_build_object('allowed', false, 'banned', true);
end;
$$;

grant execute on function public.check_device_or_register(text) to authenticated;
grant execute on function public.check_device_or_register(text) to service_role;

-- RLS: منع قراءة/تحديث الملف إذا كان المستخدم محظوراً (بعد أن يردّ RPC بحظر، الجلسة ستُغلَق من التطبيق)
drop policy if exists "Users can read own profile" on public.profiles;
create policy "Users can read own profile when not banned"
  on public.profiles for select
  using (auth.uid() = id and banned_at is null);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile when not banned"
  on public.profiles for update
  using (auth.uid() = id and banned_at is null);
