import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_user_model.dart';
import '../../../app/di.dart';

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>(
  (ref) => AdminUsersRepository(ref.read(supabaseClientProvider)),
);

class AdminUsersRepository {
  AdminUsersRepository(this._client);
  final SupabaseClient _client;

  /// جميع المستخدمين المسجلين في التطبيق (عبر RPC للأدمن) مع حالة الاشتراك
  Future<List<AdminUser>> fetchUsers() async {
    final response = await _client.rpc('admin_list_users');
    final list = response as List<dynamic>? ?? [];
    return list
        .map((e) => _rowToAdminUser(e as Map<String, dynamic>))
        .toList();
  }

  AdminUser _rowToAdminUser(Map<String, dynamic> row) {
    final createdAtStr = row['created_at']?.toString();
    return AdminUser(
      id: row['id']?.toString() ?? '',
      name: row['name']?.toString() ?? '—',
      email: row['email']?.toString() ?? '—',
      role: row['role']?.toString() ?? 'student',
      createdAt: createdAtStr != null
          ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
          : DateTime.now(),
      isSubscribed: row['is_subscribed'] == true,
    );
  }

  /// تفعيل الاشتراك للمستخدم (يفتح له جميع المميزات)
  Future<void> activateSubscription(String userId) async {
    await _client.rpc('admin_activate_subscription', params: {
      'p_user_id': userId,
    });
  }

  /// إلغاء اشتراك المستخدم
  Future<void> revokeSubscription(String userId) async {
    await _client.rpc('admin_revoke_subscription', params: {
      'p_user_id': userId,
    });
  }
}

