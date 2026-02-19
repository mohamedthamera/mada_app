import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/di.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.read(supabaseClientProvider)),
);

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// جلب الاسم ورقم الهاتف من profiles
  Future<Map<String, String?>> getProfileData() async {
    final uid = currentUserId;
    if (uid == null) return {'name': null, 'phone': null};
    try {
      final res = await _client
          .from('profiles')
          .select('name, phone')
          .eq('id', uid)
          .maybeSingle();
      if (res == null) return {'name': null, 'phone': null};
      return {
        'name': res['name']?.toString().trim(),
        'phone': res['phone']?.toString().trim(),
      };
    } catch (_) {
      return {'name': null, 'phone': null};
    }
  }

  /// تحديث الاسم في auth.user_metadata و profiles
  Future<void> updateName(String name) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('غير مسجل الدخول');
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw Exception('أدخل اسماً صحيحاً');
    await _client.auth.updateUser(UserAttributes(data: {'name': trimmed}));
    await _client.from('profiles').update({'name': trimmed}).eq('id', uid);
  }

  /// تحديث رقم الهاتف في profiles
  Future<void> updatePhone(String? phone) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('غير مسجل الدخول');
    final value = phone?.trim();
    await _client.from('profiles').update({'phone': value}).eq('id', uid);
  }

  /// تسجيل الخروج (حذف الحساب يتطلب دعم من الخادم؛ نعرض خيار تسجيل الخروج مع رسالة)
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
