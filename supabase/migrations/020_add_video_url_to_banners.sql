-- إضافة حقل video_url لجدول البنرات
alter table banners add column if not exists video_url text;

-- تحديث السياسات لتشمل الفيديوهات
create policy "Banner videos are public" on storage.objects for select using (bucket_id = 'banners');
create policy "Admins can upload banner videos" on storage.objects for insert with check (
  bucket_id = 'banners' and (select role from profiles where id = auth.uid()) = 'admin'
);
create policy "Admins can delete banner videos" on storage.objects for delete using (
  bucket_id = 'banners' and (select role from profiles where id = auth.uid()) = 'admin'
);
