-- إنشاء bucket لفيديوهات الدروس يُستخدم من لوحة الأدمن والتطبيق
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'videos',
  'videos',
  true, -- القراءة علنية، الرفع للمستخدمين المصادقين عبر السياسات
  524288000, -- 500MB لكل ملف (عدّلها حسب حاجتك)
  array[
    'video/mp4',
    'video/webm',
    'video/ogg',
    'video/quicktime'
  ]
)
on conflict (id) do nothing;

-- السماح بالقراءة العامة للفيديوهات
create policy "Public read videos"
on storage.objects for select
using (bucket_id = 'videos');

-- السماح للمستخدمين المصادقين برفع الفيديوهات
create policy "Authenticated upload videos"
on storage.objects for insert
with check (bucket_id = 'videos' and auth.role() = 'authenticated');

-- السماح للمستخدمين المصادقين بتحديث الفيديوهات
create policy "Authenticated update videos"
on storage.objects for update
using (bucket_id = 'videos' and auth.role() = 'authenticated');

-- السماح للمستخدمين المصادقين بحذف الفيديوهات
create policy "Authenticated delete videos"
on storage.objects for delete
using (bucket_id = 'videos' and auth.role() = 'authenticated');

