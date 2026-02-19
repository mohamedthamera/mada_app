-- إضافة عمود role لجدول profiles إذا كان الجدول موجوداً بدونه
alter table public.profiles
  add column if not exists role text not null default 'student';
