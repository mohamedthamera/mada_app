-- تفعيل RLS على جدول الوظائف وسياسات القراءة/الكتابة للأدمن والجميع
-- الجميع يمكنهم قراءة الوظائف (التطبيق والأدمن)، والأدمن فقط يمكنه الإضافة/التعديل/الحذف

alter table public.jobs enable row level security;

-- الجميع يمكنهم قراءة الوظائف (لتظهر في التطبيق وفي لوحة الأدمن)
create policy "Jobs are viewable by everyone"
  on public.jobs for select
  using (true);

-- الأدمن فقط: إضافة
create policy "Admins can insert jobs"
  on public.jobs for insert
  with check (
    (select trim(lower(role)) from public.profiles where id = auth.uid()) like '%admin%'
  );

-- الأدمن فقط: تحديث
create policy "Admins can update jobs"
  on public.jobs for update
  using (
    (select trim(lower(role)) from public.profiles where id = auth.uid()) like '%admin%'
  );

-- الأدمن فقط: حذف
create policy "Admins can delete jobs"
  on public.jobs for delete
  using (
    (select trim(lower(role)) from public.profiles where id = auth.uid()) like '%admin%'
  );
