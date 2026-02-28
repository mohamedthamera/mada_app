-- قائمة الوظائف للأدمن عبر RPC (تجاوز RLS وضمان ظهور البيانات)
create or replace function public.admin_list_jobs()
returns setof public.jobs
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
  if v_role is null or trim(lower(v_role)) not like '%admin%' then
    raise exception 'forbidden: admin required';
  end if;
  return query
  select *
  from public.jobs
  order by created_at desc;
end;
$$;

grant execute on function public.admin_list_jobs() to authenticated;
