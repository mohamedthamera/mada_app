-- Add avatar_url column to profiles for OAuth providers (Google, Apple)
alter table public.profiles add column if not exists avatar_url text;

-- Allow users to upsert their own profile (for OAuth sync)
drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Update handle_new_user to support OAuth metadata (full_name, avatar_url)
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, email, role, avatar_url)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'full_name',
      new.raw_user_meta_data->>'name',
      split_part(coalesce(new.email, ''), '@', 1),
      'مستخدم'
    ),
    coalesce(new.email, ''),
    'student',
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer;
