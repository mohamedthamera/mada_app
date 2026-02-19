-- إضافة عمود email إن لم يكن موجوداً
alter table public.profiles
  add column if not exists email text;

-- ملء البريد من auth.users للسجلات التي لا يوجد لها بريد
update public.profiles p
set email = u.email
from auth.users u
where p.id = u.id and (p.email is null or p.email = '');

-- إضافة عمود role إن لم يكن موجوداً
alter table public.profiles
  add column if not exists role text not null default 'student';

-- تعيين الأدمن حسب البريد من auth.users (بدون الاعتماد على عمود email في profiles)
update public.profiles
set role = 'admin'
where id = (select id from auth.users where email = 'donenk9900@gmail.com' limit 1);
