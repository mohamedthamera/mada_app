-- bucket لصور غلاف الدورات (عام للقراءة، الرفع للمصادقين)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'thumbnails',
  'thumbnails',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do nothing;

create policy "Public read thumbnails"
on storage.objects for select
using (bucket_id = 'thumbnails');

create policy "Authenticated upload thumbnails"
on storage.objects for insert
with check (bucket_id = 'thumbnails' and auth.role() = 'authenticated');

create policy "Authenticated update thumbnails"
on storage.objects for update
using (bucket_id = 'thumbnails');

create policy "Authenticated delete thumbnails"
on storage.objects for delete
using (bucket_id = 'thumbnails');
