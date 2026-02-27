-- Books security hardening: paths, private buckets, is_admin(), RLS, storage policies, constraints
-- Run after 035_books_table_and_storage.sql

-- 1) Add storage path columns (source of truth for storage.objects RLS)
alter table public.books
  add column if not exists cover_path text null,
  add column if not exists file_path text null;

comment on column public.books.cover_path is 'Storage path in book-covers bucket (e.g. covers/x.jpg)';
comment on column public.books.file_path is 'Storage path in book-files bucket (e.g. files/x.pdf)';

-- 2) Backfill cover_path / file_path from existing public URLs
-- Supabase public URL pattern: .../object/public/<bucket>/<path>
do $$
declare
  r record;
  u text;
  p text;
  bucket_cover text := 'book-covers';
  bucket_file text := 'book-files';
begin
  for r in select id, cover_url, file_url from public.books
  loop
    -- cover_path from cover_url
    if r.cover_url is not null and trim(r.cover_url) <> '' then
      u := trim(r.cover_url);
      -- Match .../object/public/book-covers/... or .../book-covers/...
      if u like '%/object/public/' || bucket_cover || '/%' then
        p := (regexp_match(u, '/object/public/' || bucket_cover || '/(.+)'))[1];
      elsif u like '%/' || bucket_cover || '/%' then
        p := (regexp_match(u, '/' || bucket_cover || '/(.+)'))[1];
      else
        p := null;
      end if;
      if p is not null and trim(p) <> '' then
        update public.books set cover_path = p where id = r.id;
      end if;
    end if;

    -- file_path from file_url
    if r.file_url is not null and trim(r.file_url) <> '' then
      u := trim(r.file_url);
      if u like '%/object/public/' || bucket_file || '/%' then
        p := (regexp_match(u, '/object/public/' || bucket_file || '/(.+)'))[1];
      elsif u like '%/' || bucket_file || '/%' then
        p := (regexp_match(u, '/' || bucket_file || '/(.+)'))[1];
      else
        p := null;
      end if;
      if p is not null and trim(p) <> '' then
        update public.books set file_path = p where id = r.id;
      end if;
    end if;
  end loop;
end $$;

-- 3) Make buckets private (no public URL access; use signed URLs for published books only)
update storage.buckets set public = false where id = 'book-files';
update storage.buckets set public = false where id = 'book-covers';

-- 4) SECURITY DEFINER helper: is the user an admin? (does not expose profiles.role to RLS expression)
create or replace function public.is_admin(uid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select trim(lower(role)) from public.profiles where id = uid limit 1),
    ''
  ) like '%admin%';
$$;

comment on function public.is_admin(uuid) is 'Returns true if the user has admin role (used by RLS).';

grant execute on function public.is_admin(uuid) to anon;
grant execute on function public.is_admin(uuid) to authenticated;

-- 5) Fix RLS on public.books: drop old policies and recreate with is_admin()
drop policy if exists "Public can read published books" on public.books;
drop policy if exists "Admins can read all books" on public.books;
drop policy if exists "Admins can insert books" on public.books;
drop policy if exists "Admins can update books" on public.books;
drop policy if exists "Admins can delete books" on public.books;

create policy "Public can read published books"
  on public.books for select
  using (is_published = true);

create policy "Admins can read all books"
  on public.books for select
  using (public.is_admin(auth.uid()));

create policy "Admins can insert books"
  on public.books for insert
  with check (public.is_admin(auth.uid()));

create policy "Admins can update books"
  on public.books for update
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

create policy "Admins can delete books"
  on public.books for delete
  using (public.is_admin(auth.uid()));

-- 6) DB constraints for correctness
alter table public.books
  drop constraint if exists books_pages_positive,
  drop constraint if exists books_sort_order_non_negative,
  drop constraint if exists books_title_non_empty,
  drop constraint if exists books_file_path_non_empty;

alter table public.books add constraint books_pages_positive
  check (pages is null or pages > 0);

alter table public.books add constraint books_sort_order_non_negative
  check (sort_order >= 0);

alter table public.books add constraint books_title_non_empty
  check (char_length(trim(title)) > 0);

-- file_path: non-empty when not null (existing rows may have null if backfill failed)
alter table public.books add constraint books_file_path_non_empty
  check (file_path is null or char_length(trim(file_path)) > 0);

-- 7) Storage: drop old policies
drop policy if exists "Book covers are public read" on storage.objects;
drop policy if exists "Admins can upload book covers" on storage.objects;
drop policy if exists "Admins can update book covers" on storage.objects;
drop policy if exists "Admins can delete book covers" on storage.objects;
drop policy if exists "Book files are public read" on storage.objects;
drop policy if exists "Admins can upload book files" on storage.objects;
drop policy if exists "Admins can update book files" on storage.objects;
drop policy if exists "Admins can delete book files" on storage.objects;

-- 8) Storage SELECT: admins read all; others only objects referenced by a published book
create policy "Admins can read book-covers"
  on storage.objects for select
  using (
    bucket_id = 'book-covers'
    and public.is_admin(auth.uid())
  );

create policy "Users can read published book covers"
  on storage.objects for select
  using (
    bucket_id = 'book-covers'
    and not public.is_admin(auth.uid())
    and exists (
      select 1 from public.books b
      where b.is_published = true
        and b.cover_path is not null
        and trim(b.cover_path) <> ''
        and b.cover_path = name
    )
  );

create policy "Admins can read book-files"
  on storage.objects for select
  using (
    bucket_id = 'book-files'
    and public.is_admin(auth.uid())
  );

create policy "Users can read published book files"
  on storage.objects for select
  using (
    bucket_id = 'book-files'
    and not public.is_admin(auth.uid())
    and exists (
      select 1 from public.books b
      where b.is_published = true
        and b.file_path is not null
        and trim(b.file_path) <> ''
        and b.file_path = name
    )
  );

-- 9) Storage INSERT: admins only; enforce bucket and extension allowlist via WITH CHECK
create policy "Admins can insert book-covers"
  on storage.objects for insert
  with check (
    bucket_id = 'book-covers'
    and public.is_admin(auth.uid())
    and (
      storage.extension(name) in ('jpg', 'jpeg', 'png', 'webp')
    )
  );

create policy "Admins can insert book-files"
  on storage.objects for insert
  with check (
    bucket_id = 'book-files'
    and public.is_admin(auth.uid())
    and storage.extension(name) in ('pdf', 'epub')
  );

-- 10) Storage UPDATE: admins only; WITH CHECK ensures bucket_id cannot be changed
create policy "Admins can update book-covers"
  on storage.objects for update
  using (
    bucket_id = 'book-covers'
    and public.is_admin(auth.uid())
  )
  with check (
    bucket_id = 'book-covers'
    and public.is_admin(auth.uid())
  );

create policy "Admins can update book-files"
  on storage.objects for update
  using (
    bucket_id = 'book-files'
    and public.is_admin(auth.uid())
  )
  with check (
    bucket_id = 'book-files'
    and public.is_admin(auth.uid())
  );

-- 11) Storage DELETE: admins only
create policy "Admins can delete book-covers"
  on storage.objects for delete
  using (
    bucket_id = 'book-covers'
    and public.is_admin(auth.uid())
  );

create policy "Admins can delete book-files"
  on storage.objects for delete
  using (
    bucket_id = 'book-files'
    and public.is_admin(auth.uid())
  );
