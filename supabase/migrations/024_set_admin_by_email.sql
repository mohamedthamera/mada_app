-- تعيين مستخدم كأدمن حسب بريده: يضمن وجود صف في profiles ويضبط role = 'admin'
-- استخدم من SQL Editor: select public.set_admin_by_email('your@email.com');

create or replace function public.set_admin_by_email(admin_email text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_name text;
begin
  if trim(coalesce(admin_email, '')) = '' then
    return 'خطأ: أدخل بريداً صحيحاً';
  end if;

  select u.id, coalesce(u.raw_user_meta_data->>'name', u.email) into v_id, v_name
  from auth.users u
  where lower(trim(u.email)) = lower(trim(admin_email))
  limit 1;

  if v_id is null then
    return 'لم يُعثر على مستخدم بالبريد: ' || admin_email;
  end if;

  insert into public.profiles (id, name, email, role)
  values (v_id, coalesce(v_name, admin_email), admin_email, 'admin')
  on conflict (id) do update set role = 'admin', email = excluded.email;

  return 'تم تعيين الأدمن بنجاح للبريد: ' || admin_email;
end;
$$;

revoke all on function public.set_admin_by_email(text) from public;
grant execute on function public.set_admin_by_email(text) to postgres;
grant execute on function public.set_admin_by_email(text) to service_role;
