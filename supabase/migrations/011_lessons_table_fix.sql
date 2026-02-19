-- توافق جدول lessons مع ما يرسله تطبيق الأدمن (إصلاح POST 400)

-- إنشاء الجدول إن لم يكن موجوداً
create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  title_ar text not null default '',
  title_en text not null default '',
  video_url text not null default '',
  duration_sec int not null default 0,
  order_index int not null default 1,
  is_free boolean not null default false,
  created_at timestamptz not null default now()
);

-- إضافة أعمدة إن كانت الجدولة ببنية قديمة (بدون title_ar, title_en, video_url, إلخ)
alter table public.lessons add column if not exists title_ar text;
alter table public.lessons add column if not exists title_en text;
alter table public.lessons add column if not exists video_url text;
alter table public.lessons add column if not exists duration_sec int;
alter table public.lessons add column if not exists order_index int;
alter table public.lessons add column if not exists is_free boolean default false;
alter table public.lessons add column if not exists created_at timestamptz default now();

-- تعيين قيم افتراضية للأعمدة الجديدة حتى يقبل الإدراج
update public.lessons set title_ar = coalesce(title_ar, ''), title_en = coalesce(title_en, ''), video_url = coalesce(video_url, ''), duration_sec = coalesce(duration_sec, 0), order_index = coalesce(order_index, 1) where title_ar is null or title_en is null or video_url is null or duration_sec is null or order_index is null;

-- جعل الأعمدة غير قابلة لـ NULL مع قيمة افتراضية (حتى لا يفشل INSERT من التطبيق)
alter table public.lessons alter column title_ar set default '';
alter table public.lessons alter column title_en set default '';
alter table public.lessons alter column video_url set default '';
alter table public.lessons alter column duration_sec set default 0;
alter table public.lessons alter column order_index set default 1;

-- إذا كان الجدول يسمح بتعديل NOT NULL بدون كسر البيانات
do $$
begin
  alter table public.lessons alter column title_ar set not null;
  alter table public.lessons alter column title_en set not null;
  alter table public.lessons alter column video_url set not null;
  alter table public.lessons alter column duration_sec set not null;
  alter table public.lessons alter column order_index set not null;
exception when others then null;
end $$;

create index if not exists idx_lessons_course on public.lessons(course_id);

notify pgrst, 'reload schema';
