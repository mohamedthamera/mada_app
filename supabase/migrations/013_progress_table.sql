-- Create progress table for tracking lesson/course progress
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

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'progress'
      and policyname = 'Allow own progress read'
  ) then
    create policy "Allow own progress read"
      on public.progress
      for select
      using (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'progress'
      and policyname = 'Allow own progress upsert'
  ) then
    create policy "Allow own progress upsert"
      on public.progress
      for insert, update
      with check (auth.uid() = user_id);
  end if;
end $$;

