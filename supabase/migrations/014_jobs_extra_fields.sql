-- حقول إضافية للوظائف: الراتب، نوع الدوام (حضوري/عن بعد/هجين)، أيام العمل، المتطلبات والخبرات
alter table public.jobs
  add column if not exists salary text,
  add column if not exists work_mode text,        -- onsite, remote, hybrid
  add column if not exists work_days text,        -- مثال: الأحد - الخميس
  add column if not exists requirements text;     -- المتطلبات والخبرات

