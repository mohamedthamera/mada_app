abstract class AuthRepository {
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<void> signOut();

  /// إرسال رابط إعادة تعيين كلمة المرور إلى البريد الإلكتروني
  Future<void> resetPasswordForEmail(String email);

  /// تحديث كلمة مرور المستخدم الحالي (بعد النقر على رابط الاستعادة)
  Future<void> updatePassword(String newPassword);
}

