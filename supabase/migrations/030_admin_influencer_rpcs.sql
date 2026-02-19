-- إدارة أكواد المؤثرين عبر RPC (بدون الاعتماد على Edge Function)
-- نفس منطق صلاحيات الأدمن: profiles.role يحتوي على admin

-- قائمة المؤثرين مع إجمالي المستخدمين (للوحة الأدمن)
create or replace function public.admin_influencer_list()
returns setof public.influencer_stats
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
  select role into v_role from public.profiles where id = v_uid;
  if v_role is null then
    raise exception 'forbidden: no profile found. Run: select set_admin_by_email(''your@email.com'');';
  end if;
  if trim(lower(v_role)) not like '%admin%' then
    raise exception 'forbidden: admin required (role=%). Set role=admin in profiles.', v_role;
  end if;
  return query
  select * from public.influencer_stats
  order by total_users desc;
end;
$$;

-- إنشاء مؤثر جديد
create or replace function public.admin_influencer_create(p_name text, p_code text)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text;
  v_row record;
begin
  if v_uid is null then
    return json_build_object('ok', false, 'message', 'not authenticated');
  end if;
  select role into v_role from public.profiles where id = v_uid;
  if v_role is null or trim(lower(v_role)) not like '%admin%' then
    return json_build_object('ok', false, 'message', 'forbidden: admin required');
  end if;
  p_name := trim(coalesce(p_name, ''));
  p_code := upper(trim(coalesce(p_code, '')));
  if p_name = '' or p_code = '' then
    return json_build_object('ok', false, 'message', 'name and code required');
  end if;
  insert into public.influencers (name, code)
  values (p_name, p_code)
  returning id, name, code, is_active, created_at into v_row;
  return json_build_object(
    'ok', true,
    'influencer', json_build_object(
      'id', v_row.id,
      'name', v_row.name,
      'code', v_row.code,
      'is_active', v_row.is_active,
      'created_at', v_row.created_at
    )
  );
exception
  when unique_violation then
    return json_build_object('ok', false, 'message', 'Code already exists');
end;
$$;

-- تفعيل/تعطيل مؤثر
create or replace function public.admin_influencer_toggle_active(p_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text;
  v_active boolean;
begin
  if v_uid is null then
    return json_build_object('ok', false, 'message', 'not authenticated');
  end if;
  select role into v_role from public.profiles where id = v_uid;
  if v_role is null or trim(lower(v_role)) not like '%admin%' then
    return json_build_object('ok', false, 'message', 'forbidden: admin required');
  end if;
  select is_active into v_active from public.influencers where id = p_id and deleted_at is null;
  if v_active is null then
    return json_build_object('ok', false, 'message', 'Influencer not found');
  end if;
  update public.influencers set is_active = not v_active where id = p_id;
  return json_build_object('ok', true, 'is_active', not v_active);
end;
$$;

-- حذف تدريجي (soft delete)
create or replace function public.admin_influencer_soft_delete(p_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text;
begin
  if v_uid is null then
    return json_build_object('ok', false, 'message', 'not authenticated');
  end if;
  select role into v_role from public.profiles where id = v_uid;
  if v_role is null or trim(lower(v_role)) not like '%admin%' then
    return json_build_object('ok', false, 'message', 'forbidden: admin required');
  end if;
  update public.influencers
  set deleted_at = now(), is_active = false
  where id = p_id;
  return json_build_object('ok', true, 'message', 'Soft deleted');
end;
$$;

grant execute on function public.admin_influencer_list() to authenticated;
grant execute on function public.admin_influencer_create(text, text) to authenticated;
grant execute on function public.admin_influencer_toggle_active(uuid) to authenticated;
grant execute on function public.admin_influencer_soft_delete(uuid) to authenticated;
