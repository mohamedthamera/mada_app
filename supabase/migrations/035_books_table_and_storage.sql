-- Books feature: table, indexes, trigger, RLS, storage buckets
-- Admins are determined by profiles.role containing 'admin' (see 025_admin_role_accept_contains).

create table if not exists public.books (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text null,
  author text null,
  category text null,
  language text null,
  pages int null,
  cover_url text null,
  file_url text not null,
  file_type text not null check (file_type in ('pdf','epub')),
  file_size_bytes bigint null,
  is_published boolean not null default false,
  is_featured boolean not null default false,
  sort_order int not null default 0,
  created_by uuid null references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.books is 'Books (PDF/EPUB) for the app; only published books visible to users.';

-- Indexes for filtering and ordering
create index if not exists idx_books_published_sort
  on public.books (is_published, sort_order asc, created_at desc);

create index if not exists idx_books_category
  on public.books (category) where category is not null;

-- Text search: pg_trgm for ilike/like on title and author
create extension if not exists pg_trgm;
create index if not exists idx_books_title_trgm
  on public.books using gin (title gin_trgm_ops);
create index if not exists idx_books_author_trgm
  on public.books using gin (author gin_trgm_ops);

-- Trigger: update updated_at on row update (uses existing set_updated_at from 021)
drop trigger if exists books_set_updated_at on public.books;
create trigger books_set_updated_at
  before update on public.books
  for each row execute function public.set_updated_at();

-- RLS
alter table public.books enable row level security;

-- Public: can only read published books
create policy "Public can read published books"
  on public.books for select
  using (is_published = true);

-- Admins: can read all
create policy "Admins can read all books"
  on public.books for select
  using (
    (select trim(lower(role)) from public.profiles where id = auth.uid()) like '%admin%'
  );

-- Admins: insert/update/delete
create policy "Admins can insert books"
  on public.books for insert
  with check (
    (select trim(lower(role)) from public.profiles where id = auth.uid()) like '%admin%'
  );

create policy "Admins can update books"
  on public.books for update
  using (
    (select trim(lower(role)) from public.profiles where id = auth.uid()) like '%admin%'
  );

create policy "Admins can delete books"
  on public.books for delete
  using (
    (select trim(lower(role)) from public.profiles where id = auth.uid()) like '%admin%'
  );

-- Storage: book-covers (images)
insert into storage.buckets (id, name, public) values ('book-covers', 'book-covers', true)
  on conflict (id) do nothing;

create policy "Book covers are public read"
  on storage.objects for select using (bucket_id = 'book-covers');

create policy "Admins can upload book covers"
  on storage.objects for insert with check (
    bucket_id = 'book-covers'
    and (select trim(lower(role)) from public.profiles where id = auth.uid()) like '%admin%'
  );

create policy "Admins can update book covers"
  on storage.objects for update using (
    bucket_id = 'book-covers'
    and (select trim(lower(role)) from public.profiles where id = auth.uid()) like '%admin%'
  );

create policy "Admins can delete book covers"
  on storage.objects for delete using (
    bucket_id = 'book-covers'
    and (select trim(lower(role)) from public.profiles where id = auth.uid()) like '%admin%'
  );

-- Storage: book-files (PDF/EPUB)
insert into storage.buckets (id, name, public) values ('book-files', 'book-files', true)
  on conflict (id) do nothing;

create policy "Book files are public read"
  on storage.objects for select using (bucket_id = 'book-files');

create policy "Admins can upload book files"
  on storage.objects for insert with check (
    bucket_id = 'book-files'
    and (select trim(lower(role)) from public.profiles where id = auth.uid()) like '%admin%'
  );

create policy "Admins can update book files"
  on storage.objects for update using (
    bucket_id = 'book-files'
    and (select trim(lower(role)) from public.profiles where id = auth.uid()) like '%admin%'
  );

create policy "Admins can delete book files"
  on storage.objects for delete using (
    bucket_id = 'book-files'
    and (select trim(lower(role)) from public.profiles where id = auth.uid()) like '%admin%'
  );
