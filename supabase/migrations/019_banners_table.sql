create table if not exists banners (
  id uuid primary key default gen_random_uuid(),
  image_url text not null,
  title text,
  link_url text,
  order_index int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Enable RLS
alter table banners enable row level security;

-- Policies for banners table
create policy "Banners are viewable by everyone" on banners for select using (true);
create policy "Banners are manageable by admins" on banners for all using (
  (select role from profiles where id = auth.uid()) = 'admin'
);

-- Storage bucket for banners
insert into storage.buckets (id, name, public) values ('banners', 'banners', true) on conflict (id) do nothing;

create policy "Banner images are public" on storage.objects for select using (bucket_id = 'banners');
create policy "Admins can upload banner images" on storage.objects for insert with check (
  bucket_id = 'banners' and (select role from profiles where id = auth.uid()) = 'admin'
);
create policy "Admins can delete banner images" on storage.objects for delete using (
  bucket_id = 'banners' and (select role from profiles where id = auth.uid()) = 'admin'
);
