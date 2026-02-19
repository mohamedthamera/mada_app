-- أعداد حقيقية للوحة الأدمن: المستخدمون المسجلون، المشتركون، الدورات، الاشتراكات، معدل الإكمال
-- يستدعيها الأدمن فقط (نفس منطق صلاحيات admin)

create or replace function public.admin_dashboard_counts()
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text;
  v_registered bigint;
  v_subscribed bigint;
  v_courses bigint;
  v_enrollments bigint;
  v_completed bigint;
  v_rate numeric;
begin
  if v_uid is null then
    return json_build_object('ok', false, 'message', 'not authenticated');
  end if;
  select role into v_role from public.profiles where id = v_uid;
  if v_role is null or trim(lower(v_role)) not like '%admin%' then
    return json_build_object('ok', false, 'message', 'forbidden: admin required');
  end if;

  -- المستخدمون المسجلون في التطبيق (من لديهم ملف في profiles وغير محظورين)
  select count(*) into v_registered from public.profiles where banned_at is null;

  -- المستخدمون المشتركون (لديهم سجل في user_subscriptions = اشتراك مدى الحياة أو تفعيل)
  select count(*) into v_subscribed from public.user_subscriptions;

  -- إضافة من جدول subscriptions النشطة إن وُجدت (اشتراكات مدفوعة)
  select count(*) into v_courses from public.courses;
  select count(*) into v_enrollments from public.enrollments;

  -- معدل الإكمال: نسبة من سجلات progress التي وصلت 100%
  select count(*) into v_completed
  from public.progress
  where progress_percent >= 100;
  if v_enrollments > 0 then
    v_rate := round((v_completed::numeric / v_enrollments::numeric * 100)::numeric, 1);
  else
    v_rate := 0;
  end if;
  v_rate := least(100, greatest(0, v_rate));

  return json_build_object(
    'ok', true,
    'registered_users', v_registered,
    'subscribed_users', v_subscribed,
    'courses', v_courses,
    'enrollments', v_enrollments,
    'completion_rate', v_rate
  );
end;
$$;

grant execute on function public.admin_dashboard_counts() to authenticated;
