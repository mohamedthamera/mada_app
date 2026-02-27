# TestSprite – خطوات التشغيل السريع

## 1. تثبيت TestSprite MCP

- في Cursor: تأكد أن **TestSprite MCP Server** مضاف في إعدادات MCP ويعمل.
- التوثيق: [TestSprite Installation](https://docs.testsprite.com/mcp/getting-started/installation)
- إن لم يكن مثبتاً: أضف السيرفر من قائمة MCP أو من إعدادات Cursor ثم أعد تشغيل الـ chat/النافذة التي ستطلب فيها الاختبار.

## 2. تشغيل التطبيق (ويب) على منفذ ثابت

في طرفية منفصلة:

```bash
cd /Users/mohammedthamer/Desktop/mada_app/apps/mobile
flutter run -d web-server --web-port=8080 --dart-define=ENV=dev
```

انتظر حتى يظهر أن التطبيق يعمل على `http://localhost:8080` (أو المنفذ الذي يظهر في الطرفية).

## 3. طلب الاختبار من المساعد (مع TestSprite MCP)

في **نافذة chat جديدة** حيث يكون TestSprite MCP **متصل**، اكتب:

```text
Help me test this project with TestSprite.
```

ثم عند الطلب:

- **مسار المشروع (projectPath):**  
  ` /Users/mohammedthamer/Desktop/mada_app `
- **المنفذ (localPort):**  
  `8080` (أو المنفذ الذي شغّلت عليه التطبيق في الخطوة 2)
- **نوع المشروع (type):**  
  `frontend`
- **نطاق الاختبار (testScope):**  
  `codebase`
- **تسجيل الدخول (needLogin):**  
  `true` إذا أردت اختبار الصفحات بعد تسجيل الدخول (الرئيسية، الدورات، الكتب، الوظائف، الاشتراك).
- **بيانات اختبار (credentials):**  
  بريد وكلمة مرور حساب اختبار في التطبيق (اختياري لكن مفيد لاختبار المسارات المحمية).

يمكنك استخدام القيم من [config.example.json](./config.example.json) وتعديل `projectPath` و `localPort` و `credentials` حسب جهازك.

## 4. مستند المتطلبات (PRD)

عندما يطلب TestSprite أو المساعد وثيقة المتطلبات، وجّههم إلى:

- **الملف:** `testsprite_tests/PRD.md`  
يحتوي على نظرة عامة على المنتج، الميزات، مسارات المستخدم، ومعايير التحقق المناسبة للاختبار.

## 5. بعد التشغيل

- ستُولَّد خطط الاختبار وملفات التنفيذ (مثل Playwright) وتُشغَّل في بيئة TestSprite.
- النتائج والتقارير ستظهر في:
  - `testsprite_tests/tmp/` (مثل `test_results.json`, `report_prompt.json`)
  - ملفات مثل `TestSprite_MCP_Test_Report.md` و `.html` في `testsprite_tests/`.

---

**ملاحظة:** إذا لم تظهر أدوات TestSprite (مثل `testsprite_bootstrap_tests`) للمساعد، فتأكد أن خادم TestSprite MCP مضاف ومفعّل في Cursor وأنك في جلسة chat تدعم MCP.
