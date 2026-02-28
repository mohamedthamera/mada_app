-- إضافة اسم المستخدم لجدول profiles وإنشاؤه عند التسجيل وعرضه في قائمة الأدمن

-- عمود اسم المستخدم (فريد، اختياري للتوافق مع السجلات القديمة)
alter table public.profiles add column if not exists username text;

create unique index if not exists profiles_username_key
  on public.profiles (lower(trim(username)))
  where username is not null and trim(username) != '';

-- تعبئة username للمستخدمين القدامى: الجزء قبل @ من البريد + جزء من id
update public.profiles
set username = lower(regexp_replace(
  coalesce(nullif(trim(split_part(email, '@', 1)), ''), 'user') || '_' || substr(id::text, 1, 8),
  '[^a-z0-9_]', '', 'g'
))
where username is null or trim(username) = '';

-- تحديث دالة إنشاء الملف عند التسجيل لنسخ username من raw_user_meta_data
create or replace function public.handle_new_user()
returns trigger as $$
declare
  v_username text;
begin
  v_username := nullif(trim(new.raw_user_meta_data->>'username'), '');
  if v_username is null then
    v_username := lower(regexp_replace(
      coalesce(
        new.raw_user_meta_data->>'full_name',
        new.raw_user_meta_data->>'name',
        split_part(coalesce(new.email, ''), '@', 1)
      ),
      '[^a-zA-Z0-9_\u0600-\u06FF]', '', 'g'
    ));
    if length(v_username) > 20 then
      v_username := left(v_username, 20);
    end if;
    if v_username is null or v_username = '' then
      v_username := 'user_' || substr(new.id::text, 1, 8);
    else
      v_username := v_username || '_' || substr(new.id::text, 1, 6);
    end if;
  end if;
  insert into public.profiles (id, name, email, role, avatar_url, username)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'full_name',
      new.raw_user_meta_data->>'name',
      split_part(coalesce(new.email, ''), '@', 1),
      'مستخدم'
    ),
    coalesce(new.email, ''),
    'student',
    new.raw_user_meta_data->>'avatar_url',
    v_username
  );
  return new;
end;
$$ language plpgsql security definer;

-- إضافة username إلى نتيجة admin_list_users
drop function if exists public.admin_list_users();

create or replace function public.admin_list_users()
returns table (
  id uuid,
  name text,
  email text,
  username text,
  role text,
  created_at timestamptz,
  is_subscribed boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;
  select profiles.role into v_role from public.profiles where profiles.id = v_uid;
  if v_role is null or trim(lower(v_role)) not like '%admin%' then
    raise exception 'forbidden: admin required';
  end if;
  return query
  select
    p.id,
    p.name,
    p.email,
    coalesce(p.username, '')::text,
    p.role,
    p.created_at,
    exists(
      select 1 from public.user_subscriptions us
      where us.user_id = p.id and us.is_lifetime = true
    ) as is_subscribed
  from public.profiles p
  where p.banned_at is null
  order by p.created_at desc;
end;
$$;

grant execute on function public.admin_list_users() to authenticated;
