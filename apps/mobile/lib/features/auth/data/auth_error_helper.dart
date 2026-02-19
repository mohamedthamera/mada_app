/// ترجمة أخطاء Supabase Auth إلى رسائل عربية
String authErrorMessage(dynamic e) {
  final msg = e.toString().toLowerCase();
  if (msg.contains('invalid login credentials') ||
      msg.contains('invalid_credentials')) {
    return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
  }
  if (msg.contains('email not confirmed')) {
    return 'يرجى تأكيد بريدك الإلكتروني من الرابط المرسل إليك';
  }
  if (msg.contains('user already registered') ||
      msg.contains('already registered')) {
    return 'هذا البريد مسجل مسبقاً. سجّل الدخول أو استعد كلمة المرور';
  }
  if (msg.contains('over_email_send_rate_limit') ||
      msg.contains('email rate limit exceeded') ||
      msg.contains('429')) {
    return 'تم إرسال عدد كبير من رسائل البريد في مدة قصيرة.\nانتظر بضع دقائق ثم حاول مرة أخرى، أو استخدم بريداً إلكترونياً مختلفاً.';
  }
  if (msg.contains('password')) {
    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
  }
  // فقط إن كان الخطأ يشير صراحة إلى صيغة البريد
  if ((msg.contains('invalid') && msg.contains('email')) ||
      msg.contains('valid email') ||
      msg.contains('email format')) {
    return 'البريد الإلكتروني غير صالح';
  }
  // في الحالات الأخرى أظهر رسالة الخطأ الأصلية للمساعدة في التشخيص
  return 'حدث خطأ غير متوقع:\n${e.toString()}';
}
