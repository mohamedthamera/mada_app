-- تعيين حساب الأدمن: عند إنشاء أي profile بهذا البريد يُعطى دور admin تلقائياً
create or replace function public.set_admin_by_email()
returns trigger as $$
begin
  if new.email = 'donenk9900@gmail.com' then
    new.role := 'admin';
  end if;
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger before_insert_profile_set_admin
  before insert on public.profiles
  for each row execute procedure public.set_admin_by_email();

-- إذا كان الحساب موجوداً مسبقاً، حدّث دوره الآن
update public.profiles
set role = 'admin'
where email = 'donenk9900@gmail.com';
