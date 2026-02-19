-- إضافة عمود رقم الهاتف لجدول profiles
alter table public.profiles add column if not exists phone text;
