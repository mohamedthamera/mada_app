-- bucket لملفات الدروس (pdf/txt/doc/docx) - عام للقراءة، الرفع للمصادقين
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'uploads',
  'uploads',
  true,
  52428800, -- 50MB لكل ملف (عدّلها حسب حاجتك)
  array[
    'text/plain',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ]
)
on conflict (id) do nothing;

-- السماح بالقراءة العامة لملفات الدروس
create policy "Public read uploads"
on storage.objects for select
using (bucket_id = 'uploads');

-- السماح للمستخدمين المصادقين برفع الملفات
create policy "Authenticated upload uploads"
on storage.objects for insert
with check (bucket_id = 'uploads' and auth.role() = 'authenticated');

-- السماح للمستخدمين المصادقين بتحديث الملفات
create policy "Authenticated update uploads"
on storage.objects for update
using (bucket_id = 'uploads' and auth.role() = 'authenticated');

-- السماح للمستخدمين المصادقين بحذف الملفات
create policy "Authenticated delete uploads"
on storage.objects for delete
using (bucket_id = 'uploads' and auth.role() = 'authenticated');

