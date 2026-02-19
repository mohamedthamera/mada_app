import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/di.dart';

final adminSubscriptionsRepositoryProvider =
    Provider<AdminSubscriptionsRepository>(
  (ref) => AdminSubscriptionsRepository(ref.read(supabaseClientProvider)),
);

class AdminSubscriptionsRepository {
  AdminSubscriptionsRepository(this._client);
  final SupabaseClient _client;

  /// قائمة المستخدمين المشتركين (من user_subscriptions مع الاسم والبريد)
  Future<List<Map<String, dynamic>>> fetchSubscribedUsers() async {
    final res = await _client.rpc('admin_list_subscribed_users');
    final list = res as List<dynamic>? ?? [];
    return list
        .map((e) => _mapSubscribed(e as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> _mapSubscribed(Map<String, dynamic> row) {
    return {
      'userId': row['user_id']?.toString() ?? '',
      'name': row['name']?.toString() ?? '—',
      'email': row['email']?.toString() ?? '—',
      'isLifetime': row['is_lifetime'] == true,
      'source': row['source']?.toString() ?? '—',
      'activatedAt': _parseDate(row['activated_at']),
      'createdAt': _parseDate(row['created_at']),
    };
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}
