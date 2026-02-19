-- جدول الوظائف ليُستخدم من تطبيق الأدمن وتطبيق الموبايل
create table if not exists jobs (
  id uuid primary key default gen_random_uuid(),
  title_ar text not null,
  company_name text not null,
  location text not null,
  job_type text not null, -- full_time, part_time, internship
  description_ar text not null,
  apply_url text,
  created_at timestamptz not null default now()
);

create index if not exists idx_jobs_created_at on jobs(created_at);

