-- قائمة جميع المستخدمين المسجلين (للأدمن فقط)
-- قائمة المستخدمين المشتركين (من user_subscriptions مع بيانات الملف)

-- جميع المستخدمين المسجلين في التطبيق (من profiles)
create or replace function public.admin_list_users()
returns table (
  id uuid,
  name text,
  email text,
  role text,
  created_at timestamptz
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
    p.created_at
  from public.profiles p
  where p.banned_at is null
  order by p.created_at desc;
end;
$$;

-- قائمة المستخدمين المشتركين (لديهم سجل في user_subscriptions) مع الاسم والبريد
create or replace function public.admin_list_subscribed_users()
returns table (
  user_id uuid,
  name text,
  email text,
  is_lifetime boolean,
  source text,
  activated_at timestamptz,
  created_at timestamptz
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
    us.user_id,
    p.name,
    p.email,
    us.is_lifetime,
    us.source,
    us.activated_at,
    us.created_at
  from public.user_subscriptions us
  left join public.profiles p on p.id = us.user_id
  order by us.created_at desc;
end;
$$;

grant execute on function public.admin_list_users() to authenticated;
grant execute on function public.admin_list_subscribed_users() to authenticated;
