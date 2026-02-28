abstract class AuthRepository {
  /// تسجيل الدخول بالبريد الإلكتروني أو اسم المستخدم + كلمة المرور
  Future<void> signIn({
    required String emailOrUsername,
    required String password,
  });
  Future<void> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
  });
  Future<void> signOut();

  /// إرسال رابط إعادة تعيين كلمة المرور إلى البريد الإلكتروني
  Future<void> resetPasswordForEmail(String email);

  /// تحديث كلمة مرور المستخدم الحالي (بعد النقر على رابط الاستعادة)
  Future<void> updatePassword(String newPassword);
}

