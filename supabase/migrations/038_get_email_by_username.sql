-- استرجاع البريد الإلكتروني لاسم مستخدم معيّن (للتسجيل بالبريد أو اسم المستخدم)
-- يُستدعى من التطبيق عند تسجيل الدخول باسم المستخدم لتحويله إلى بريد ثم استدعاء signInWithPassword
create or replace function public.get_email_by_username(p_username text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text;
begin
  if p_username is null or trim(p_username) = '' then
    return null;
  end if;
  select p.email into v_email
  from public.profiles p
  where lower(trim(p.username)) = lower(trim(p_username))
  limit 1;
  return v_email;
end;
$$;

-- السماح للمستخدمين غير المسجلين (anon) باستدعاء الدالة لتسجيل الدخول
grant execute on function public.get_email_by_username(text) to anon;
grant execute on function public.get_email_by_username(text) to authenticated;
