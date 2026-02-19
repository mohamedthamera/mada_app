-- إنشاء bucket للفيديوهات (عام للقراءة، الرفع للمصادقين)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'videos',
  'videos',
  true,
  524288000,
  array['video/mp4', 'video/webm', 'video/quicktime', 'video/x-msvideo']
)
on conflict (id) do nothing;

-- أي شخص يمكنه قراءة الملفات (فيديوهات عامة)
create policy "Public read videos"
on storage.objects for select
using (bucket_id = 'videos');

-- المستخدمون المصادقون يمكنهم الرفع
create policy "Authenticated upload videos"
on storage.objects for insert
with check (bucket_id = 'videos' and auth.role() = 'authenticated');

create policy "Authenticated update own videos"
on storage.objects for update
using (bucket_id = 'videos');

create policy "Authenticated delete own videos"
on storage.objects for delete
using (bucket_id = 'videos');
