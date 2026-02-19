/// نموذج مستخدم في لوحة الأدمن مع حالة الاشتراك
class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.isSubscribed,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
  final bool isSubscribed;
}
