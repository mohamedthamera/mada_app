-- إضافة أعمدة ملفات الدرس (روابط + أسماء) إلى جدول lessons
alter table public.lessons
  add column if not exists text_file_urls text[] default '{}'::text[];

alter table public.lessons
  add column if not exists text_file_names text[] default '{}'::text[];

-- ضمان عدم وجود nulls (للتوافق مع تطبيق الموبايل/الأدمن)
update public.lessons
set
  text_file_urls = coalesce(text_file_urls, '{}'::text[]),
  text_file_names = coalesce(text_file_names, '{}'::text[])
where text_file_urls is null or text_file_names is null;

alter table public.lessons
  alter column text_file_urls set not null;

alter table public.lessons
  alter column text_file_names set not null;

