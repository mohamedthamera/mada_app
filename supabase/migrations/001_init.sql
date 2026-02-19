create table if not exists profiles (
  id uuid primary key references auth.users(id),
  name text not null,
  email text not null,
  role text not null default 'student',
  created_at timestamptz not null default now()
);

create table if not exists courses (
  id uuid primary key default gen_random_uuid(),
  title_ar text not null,
  title_en text not null,
  desc_ar text not null,
  desc_en text not null,
  category_id uuid not null,
  level text not null,
  thumbnail_url text not null,
  rating_avg numeric not null default 0,
  rating_count int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists lessons (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses(id) on delete cascade,
  title_ar text not null,
  title_en text not null,
  video_url text not null,
  duration_sec int not null,
  order_index int not null,
  is_free boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists enrollments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null references courses(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null references courses(id) on delete cascade,
  lesson_id uuid not null references lessons(id) on delete cascade,
  progress_percent numeric not null default 0,
  watched_seconds int not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null references courses(id) on delete cascade,
  rating int not null,
  comment text,
  created_at timestamptz not null default now()
);

create table if not exists discussions (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references courses(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  body text not null,
  created_at timestamptz not null default now()
);

create table if not exists comments (
  id uuid primary key default gen_random_uuid(),
  discussion_id uuid not null references discussions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  body text not null,
  type text not null,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create table if not exists certificates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null references courses(id) on delete cascade,
  issued_at timestamptz not null default now(),
  verification_code text not null
);

create table if not exists subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null,
  status text not null,
  started_at timestamptz not null default now(),
  expires_at timestamptz
);

create index if not exists idx_courses_category on courses(category_id);
create index if not exists idx_lessons_course on lessons(course_id);
create index if not exists idx_progress_user on progress(user_id);
create index if not exists idx_notifications_user on notifications(user_id);

