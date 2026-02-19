import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/di.dart';

final adminInfluencerRepositoryProvider = Provider<AdminInfluencerRepository>(
  (ref) => AdminInfluencerRepository(ref.read(supabaseClientProvider)),
);

/// إدارة أكواد المؤثرين عبر RPC في قاعدة البيانات (بدون Edge Function).
class AdminInfluencerRepository {
  AdminInfluencerRepository(this._client);

  final SupabaseClient _client;

  static String _err(Object e) =>
      e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  Future<List<Map<String, dynamic>>> list() async {
    try {
      final list = await _client.rpc('admin_influencer_list');
      if (list is! List) return [];
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception(_err(e));
    }
  }

  Future<Map<String, dynamic>> create({required String name, required String code}) async {
    try {
      final data = await _client.rpc(
        'admin_influencer_create',
        params: {
          'p_name': name.trim(),
          'p_code': code.trim().toUpperCase(),
        },
      );
      if (data is! Map<String, dynamic>) throw Exception('استجابة غير متوقعة');
      if (data['ok'] != true) {
        throw Exception((data['message'] ?? 'Unknown error').toString());
      }
      final inf = data['influencer'];
      return inf is Map<String, dynamic> ? inf : {};
    } catch (e) {
      throw Exception(_err(e));
    }
  }

  Future<void> toggleActive(String id) async {
    try {
      final data = await _client.rpc(
        'admin_influencer_toggle_active',
        params: {'p_id': id},
      );
      if (data is! Map<String, dynamic> || data['ok'] != true) {
        throw Exception((data is Map ? data['message'] : 'Unknown error').toString());
      }
    } catch (e) {
      throw Exception(_err(e));
    }
  }

  Future<void> delete(String id) async {
    try {
      final data = await _client.rpc(
        'admin_influencer_soft_delete',
        params: {'p_id': id},
      );
      if (data is! Map<String, dynamic> || data['ok'] != true) {
        throw Exception((data is Map ? data['message'] : 'Unknown error').toString());
      }
    } catch (e) {
      throw Exception(_err(e));
    }
  }
}
