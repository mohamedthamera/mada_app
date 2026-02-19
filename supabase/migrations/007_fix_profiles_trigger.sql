-- التأكد من وجود كل الأعمدة المطلوبة في profiles (لتفادي فشل الـ trigger)
alter table public.profiles add column if not exists name text default 'مستخدم';
alter table public.profiles add column if not exists email text;
alter table public.profiles add column if not exists role text not null default 'student';

-- تعبئة name و email من auth.users للسجلات القديمة
update public.profiles p
set
  name = coalesce(nullif(trim(p.name), ''), u.raw_user_meta_data->>'name', 'مستخدم'),
  email = coalesce(nullif(trim(p.email), ''), u.email)
from auth.users u
where p.id = u.id;

-- إعادة إنشاء الدالة والـ trigger لإنشاء profile عند كل تسجيل جديد
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', 'مستخدم'),
    coalesce(new.email, ''),
    'student'
  );
  return new;
end;
$$ language plpgsql security definer;

-- إزالة الـ trigger القديم إن وُجد ثم إضافته من جديد
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
