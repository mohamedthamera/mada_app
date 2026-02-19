-- إضافة أعمدة جدول lessons فقط (بدون تعديل NOT NULL أو تحديث بيانات)
-- شغّل هذا في SQL Editor إن استمر خطأ 400 عند إضافة درس.

-- إنشاء الجدول إن لم يكن موجوداً
create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  title_ar text not null default '',
  title_en text not null default '',
  video_url text not null default '',
  duration_sec integer not null default 0,
  order_index integer not null default 1,
  is_free boolean not null default false,
  created_at timestamptz not null default now()
);

-- إضافة أي عمود ناقص (الاسم والصيغة كما يرسلها التطبيق)
alter table public.lessons add column if not exists title_ar text default '';
alter table public.lessons add column if not exists title_en text default '';
alter table public.lessons add column if not exists video_url text default '';
alter table public.lessons add column if not exists duration_sec integer default 0;
alter table public.lessons add column if not exists order_index integer default 1;
alter table public.lessons add column if not exists is_free boolean default false;
alter table public.lessons add column if not exists created_at timestamptz default now();

create index if not exists idx_lessons_course on public.lessons(course_id);

-- إعادة تحميل schema لـ PostgREST
notify pgrst, 'reload schema';
