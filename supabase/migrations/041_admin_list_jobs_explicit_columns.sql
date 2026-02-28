-- إعادة إنشاء admin_list_jobs بإرجاع أعمدة صريحة لضمان توافق التطبيق مع شكل الاستجابة
drop function if exists public.admin_list_jobs();

create or replace function public.admin_list_jobs()
returns table (
  id uuid,
  title_ar text,
  company_name text,
  location text,
  job_type text,
  description_ar text,
  apply_url text,
  salary text,
  work_mode text,
  work_days text,
  requirements text,
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
  select role into v_role from public.profiles where id = v_uid;
  if v_role is null or trim(lower(v_role)) not like '%admin%' then
    raise exception 'forbidden: admin required';
  end if;
  return query
  select
    j.id,
    j.title_ar,
    j.company_name,
    j.location,
    j.job_type,
    j.description_ar,
    j.apply_url,
    j.salary,
    j.work_mode,
    j.work_days,
    j.requirements,
    j.created_at
  from public.jobs j
  order by j.created_at desc;
end;
$$;

grant execute on function public.admin_list_jobs() to authenticated;
