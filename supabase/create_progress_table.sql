-- إنشاء جدول progress لتتبع تقدم المستخدم في الدروس
create table if not exists public.progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  course_id text not null,
  lesson_id text not null,
  progress_percent double precision not null default 0,
  watched_seconds integer not null default 0,
  updated_at timestamptz not null default now()
);

alter table public.progress enable row level security;

-- السماح للمستخدم بقراءة تقدمه فقط
drop policy if exists "Allow own progress read" on public.progress;
create policy "Allow own progress read"
  on public.progress
  for select
  using (auth.uid() = user_id);

-- السماح للمستخدم بإضافة وتحديث تقدمه فقط
drop policy if exists "Allow own progress upsert" on public.progress;
create policy "Allow own progress upsert"
  on public.progress
  for insert
  with check (auth.uid() = user_id);

drop policy if exists "Allow own progress update" on public.progress;
create policy "Allow own progress update"
  on public.progress
  for update
  using (auth.uid() = user_id);
