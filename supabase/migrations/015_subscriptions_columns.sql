-- التأكد من وجود أعمدة started_at و expires_at في جدول الاشتراكات (لصفحة الأدمن)
alter table if exists public.subscriptions
  add column if not exists started_at timestamptz not null default now();

alter table if exists public.subscriptions
  add column if not exists expires_at timestamptz;
