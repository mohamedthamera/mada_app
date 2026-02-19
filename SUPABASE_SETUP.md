# إعداد Supabase لمشروع Mada

هذا الملف يوضح الخطوات المطلوبة في **لوحة تحكم Supabase** (والأوامر المحلية) لتفعيل كل المزايا وتجنب الأخطاء.

---

## 1. المشروع والبيانات

- **URL المشروع**: من `Project Settings` → API: `SUPABASE_URL` و `SUPABASE_ANON_KEY`.
- تأكد أن ملفات `.env` في `apps/admin` و `apps/mobile` تحتوي نفس القيم للمشروع الذي تستخدمه.

---

## 2. صلاحيات الأدمن (مهم لـ Generate Codes ولوحة الأدمن)

### الطريقة الأسهل: تعيين الأدمن بالبريد (دالة واحدة)

1. طبّق migration **024** مرة واحدة (من **SQL Editor** انسخ محتوى `supabase/migrations/024_set_admin_by_email.sql` ونفّذه).
2. من **SQL Editor** نفّذ الاستعلام التالي بعد استبدال البريد ببريدك الذي تسجّل به في لوحة الأدمن:
   ```sql
   select set_admin_by_email('your@email.com');
   ```
3. يجب أن تظهر رسالة: `تم تعيين الأدمن بنجاح للبريد: ...`
4. حدّث صفحة لوحة الأدمن (أو سجّل خروج ثم دخول) وجرّب **توليد الأكواد**.

هذه الطريقة تضمن وجود صف في جدول `profiles` لحسابك وتضبط `role = 'admin'` تلقائياً.

**بديل بدون الدالة:** إذا ظهر خطأ صلاحيات عند تنفيذ الدالة، نفّذ هذا الاستعلام بعد استبدال البريد:
```sql
insert into public.profiles (id, name, email, role)
select id, coalesce(raw_user_meta_data->>'name', email), email, 'admin'
from auth.users where email = 'your@email.com'
on conflict (id) do update set role = 'admin';
```

### الطريقة اليدوية: من جدول `profiles`

1. من Supabase: **Table Editor** → جدول **`profiles`**.
2. ابحث عن الصف الذي **عمود id يطابق المستخدم الذي تسجّل به** (نفس الـ id في **Authentication** → **Users**).
3. عدّل عمود **`role`** إلى **`admin`** (أحرف صغيرة).
4. إن لم يكن هناك صف لحسابك، أضف صفاً جديداً: **id** = نفس id المستخدم من Authentication، **role** = `admin`.

---

## 3. تشغيل الهجرات (Migrations)

يجب تطبيق الهجرات على قاعدة البيانات مرة واحدة. لك خياران:

---

### الطريقة أ: من لوحة Supabase (SQL Editor)

1. افتح المتصفح وادخل إلى: **https://supabase.com/dashboard**
2. سجّل الدخول واختر مشروع **mada_app** (أو المشروع الذي تستخدمه).
3. من القائمة الجانبية اليسرى اختر: **SQL Editor** (أيقونة </> أو "SQL Editor").
4. اضغط **New query** لإنشاء استعلام جديد.
5. افتح من مشروعك الملف الأول من الهجرات، مثلاً:  
   `supabase/migrations/001_init.sql`  
   انسخ **كل** محتوى الملف والصقه في صندوق الاستعلام.
6. اضغط **Run** (أو Ctrl+Enter / Cmd+Enter).
7. كرر الخطوات 5 و 6 لكل ملف في `supabase/migrations/` **بالترتيب العددي**:  
   `001_init.sql` → `002_...` → `003_...` → … → `022_admin_generate_lifetime_codes_rpc.sql`.

**ملاحظة:** إذا كانت بعض الهجرات مُطبَّقة مسبقاً قد تظهر أخطاء مثل "already exists". يمكنك تخطي الملف الذي يسبب الخطأ والمتابعة، أو تنفيذ فقط الملفات الجديدة (مثل `022_admin_generate_lifetime_codes_rpc.sql` إن لم تكن مطبقة).

---

### الطريقة ب: من الطرفية (Supabase CLI)

1. افتح **Terminal** وانتقل لمجلد المشروع:
   ```bash
   cd /Users/mohammedthamer/Desktop/mada_app
   ```
2. اربط المشروع مرة واحدة (إن لم يكن مربوطاً):
   ```bash
   npx supabase link --project-ref wzbaedyivgosgduvpgjg
   ```
   عند الطلب اختر المشروع **mada_app** أو أدخل كلمة مرور قاعدة البيانات إن طُلبت.
3. طبّق كل الهجرات دفعة واحدة:
   ```bash
   npx supabase db push
   ```
   ستُطبَّق تلقائياً كل الملفات في `supabase/migrations/` التي لم تُطبَّق بعد.

بهذا تكون الهجرات (بما فيها `022_admin_generate_lifetime_codes_rpc.sql`) مطبقة على المشروع.

---

## 4. نشر Edge Functions (اختياري لتوليد الأكواد)

**توليد أكواد الاشتراك الدائم** يعمل الآن عبر RPC فقط (بدون Edge Function)، لذلك لا تحتاج نشر أي دالة لزر "توليد الأكواد". إن كنت تحتاج دوال أخرى (مثل الدفع):

1. تثبيت Supabase CLI إن لم يكن مثبتاً:  
   `npm i -g supabase` أو من الموقع الرسمي.
2. ربط المشروع:
   ```bash
   cd /path/to/mada_app
   npx supabase link --project-ref wzbaedyivgosgduvpgjg
   ```
   (استبدل `wzbaedyivgosgduvpgjg` بمرجع مشروعك إن كان مختلفاً.)
3. تعيين الأسرار للدالة (مهم لـ Generate Codes):
   ```bash
   npx supabase secrets set ADMIN_EMAILS=your-admin@email.com
   ```
   (يمكن إضافة أكثر من بريد مفصول بفاصلة.)
4. نشر الدوال:
   ```bash
   npx supabase functions deploy generate_lifetime_codes
   npx supabase functions deploy manage_influencer_codes   # مطلوب لصفحة «أكواد المؤثرين» في لوحة الأدمن
   npx supabase functions deploy create_payment_session   # إن استخدمت الدفع
   npx supabase functions deploy payment_webhook         # إن استخدمت الويبهوك
   ```

الأسرار مثل `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` تُضاف تلقائياً عند النشر للمشروع المربوط؛ أنت تحتاج فقط لضبط **ADMIN_EMAILS** كما فوق (أو من لوحة التحكم).

### صفحة «أكواد المؤثرين» تظهر Failed to fetch

هذا يحدث عندما **لم تُنشر** دالة Edge الخاصة بأكواد المؤثرين. نفّذ من مجلد المشروع:

```bash
npx supabase link --project-ref wzbaedyivgosgduvpgjg   # إن لم يكن مربوطاً
npx supabase functions deploy manage_influencer_codes
```

ثم حدّث صفحة لوحة الأدمن → أكواد المؤثرين.

---

## 5. حل أخطاء شائعة

### خطأ عند الضغط على "توليد الأكواد"

- التوليد يعمل **فقط عبر RPC** `admin_generate_lifetime_codes` (لا يستخدم Edge Function)، فلا يظهر خطأ 401 أو Invalid JWT لهذه الميزة.
- تأكد أنك **طبّقت migration 022** (دالة `admin_generate_lifetime_codes` موجودة في قاعدة البيانات).
- تأكد أن حسابك له **`profiles.role = 'admin'`** في جدول `profiles`.
- إذا ظهر "صلاحية الأدمن مطلوبة": عدّل عمود `role` إلى `admin` للصف الخاص بحسابك في جدول `profiles` ثم حدّث الصفحة أو سجّل الخروج والدخول مرة أخرى.

### Forbidden: not admin

- تأكد أن عمود **`role`** في جدول **`profiles`** لهذا المستخدم = **`admin`** (نص بالضبط).
- أو أن بريد هذا المستخدم مضاف في **ADMIN_EMAILS** لـ Edge Function.

### الجداول أو الدوال غير موجودة

- تأكد أنك نفذت **كل** الملفات في `supabase/migrations/` على نفس المشروع (من SQL Editor أو `supabase db push`).

### أكواد المؤثرين: خطأ أو قائمة فارغة

- صفحة «أكواد المؤثرين» تعمل عبر **RPC** في قاعدة البيانات (لا تحتاج Edge Function).
- تأكد من تطبيق migration **028** (جداول المؤثرين والإحالة) و **030** (دوال الأدمن: `admin_influencer_list`, `admin_influencer_create`, إلخ).
- نفّذ `npx supabase db push` أو نفّذ محتوى `030_admin_influencer_rpcs.sql` من SQL Editor.
- تأكد أن حسابك له `profiles.role = 'admin'` حتى تستطيع استدعاء دوال الأدمن.

---

## 6. ملخص سريع

| المطلوب | أين |
|--------|-----|
| `SUPABASE_URL` و `SUPABASE_ANON_KEY` | `.env` في admin و mobile |
| صلاحية أدمن | `profiles.role = 'admin'` أو `ADMIN_EMAILS` في أسرار الدوال |
| الهجرات | تشغيل محتويات `supabase/migrations/` على المشروع |
| توليد الأكواد | تطبيق migration 022 + `profiles.role = 'admin'` فقط (لا حاجة لـ Edge Function) |

بعد تطبيق الخطوات أعلاه، لوحة الأدمن وزر **Generate** يجب أن يعملا مع Supabase بدون مشاكل صلاحيات أو JWT.
