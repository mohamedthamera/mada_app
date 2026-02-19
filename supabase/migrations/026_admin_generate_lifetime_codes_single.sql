-- إزالة تكرار الدالة: قد تكون هناك نسخة قديمة بمعامل p_prefix.
-- نحذف كل التوقيعات ثم ننشئ دالة واحدة فقط (3 معاملات) لتفادي خطأ "Could not choose the best candidate function".

drop function if exists public.admin_generate_lifetime_codes(int, timestamptz, int);
drop function if exists public.admin_generate_lifetime_codes(int, text, timestamptz, int);

create or replace function public.admin_generate_lifetime_codes(
  p_count int default 10,
  p_expires_at timestamptz default null,
  p_max_redemptions int default 1
)
returns table (code text, expires_at timestamptz, max_redemptions int)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text;
  i int;
  v_code text;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  select role into v_role from public.profiles where id = v_uid;
  if v_role is null then
    raise exception 'forbidden: no profile found (user_id=%). Run: select set_admin_by_email(''your@email.com'');', v_uid;
  end if;
  if trim(lower(v_role)) not like '%admin%' then
    raise exception 'forbidden: admin required (user_id=%, role=[%]). Set role=admin for this id in profiles.', v_uid, v_role;
  end if;

  p_count := greatest(1, least(coalesce(p_count, 10), 1000));
  p_max_redemptions := greatest(1, least(coalesce(p_max_redemptions, 1), 1000));

  for i in 1 .. p_count loop
    v_code := upper(
      substr(md5(gen_random_uuid()::text || i::text || clock_timestamp()::text), 1, 4) || '-' ||
      substr(md5(gen_random_uuid()::text || (i+1)::text || clock_timestamp()::text), 1, 4) || '-' ||
      substr(md5(gen_random_uuid()::text || (i+2)::text || clock_timestamp()::text), 1, 4) || '-' ||
      substr(md5(gen_random_uuid()::text || (i+3)::text || clock_timestamp()::text), 1, 4)
    );
    insert into public.lifetime_codes (code, created_by, expires_at, max_redemptions)
    values (v_code, v_uid, p_expires_at, p_max_redemptions);
    code := v_code;
    expires_at := p_expires_at;
    max_redemptions := p_max_redemptions;
    return next;
  end loop;
end;
$$;

revoke all on function public.admin_generate_lifetime_codes(int, timestamptz, int) from public;
grant execute on function public.admin_generate_lifetime_codes(int, timestamptz, int) to authenticated;
