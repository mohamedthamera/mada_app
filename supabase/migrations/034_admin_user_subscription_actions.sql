-- إرجاع حالة الاشتراك مع قائمة المستخدمين + دوال تفعيل/إلغاء الاشتراك للأدمن

-- السماح لمصدر 'admin' في user_subscriptions
alter table public.user_subscriptions
  drop constraint if exists user_subscriptions_source_check;
alter table public.user_subscriptions
  add constraint user_subscriptions_source_check
  check (source is null or source in ('code','gateway','admin'));

-- إسقاط الدالة القديمة لأن نوع الإرجاع تغيّر (إضافة is_subscribed)
drop function if exists public.admin_list_users();

-- إعادة إنشاء admin_list_users مع عمود is_subscribed
create or replace function public.admin_list_users()
returns table (
  id uuid,
  name text,
  email text,
  role text,
  created_at timestamptz,
  is_subscribed boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;
  select profiles.role into v_role from public.profiles where profiles.id = v_uid;
  if v_role is null or trim(lower(v_role)) not like '%admin%' then
    raise exception 'forbidden: admin required';
  end if;
  return query
  select
    p.id,
    p.name,
    p.email,
    p.role,
    p.created_at,
    exists(
      select 1 from public.user_subscriptions us
      where us.user_id = p.id and us.is_lifetime = true
    ) as is_subscribed
  from public.profiles p
  where p.banned_at is null
  order by p.created_at desc;
end;
$$;

grant execute on function public.admin_list_users() to authenticated;

-- تفعيل اشتراك مستخدم (من لوحة الأدمن)
create or replace function public.admin_activate_subscription(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;
  select profiles.role into v_role from public.profiles where profiles.id = v_uid;
  if v_role is null or trim(lower(v_role)) not like '%admin%' then
    raise exception 'forbidden: admin required';
  end if;
  insert into public.user_subscriptions(user_id, is_lifetime, source, activated_at)
  values (p_user_id, true, 'admin', now())
  on conflict (user_id) do update
  set is_lifetime = true,
      source = 'admin',
      activated_at = excluded.activated_at,
      updated_at = now();
end;
$$;

-- إلغاء اشتراك مستخدم (من لوحة الأدمن)
create or replace function public.admin_revoke_subscription(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;
  select profiles.role into v_role from public.profiles where profiles.id = v_uid;
  if v_role is null or trim(lower(v_role)) not like '%admin%' then
    raise exception 'forbidden: admin required';
  end if;
  delete from public.user_subscriptions where user_id = p_user_id;
end;
$$;

grant execute on function public.admin_activate_subscription(uuid) to authenticated;
grant execute on function public.admin_revoke_subscription(uuid) to authenticated;
