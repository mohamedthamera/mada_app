import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/di.dart';

final referralRepositoryProvider = Provider<ReferralRepository>(
  (ref) => ReferralRepository(ref.read(supabaseClientProvider)),
);

class ReferralRepository {
  ReferralRepository(this._client);

  final SupabaseClient _client;

  /// Apply referral code for current user. Fails if already set or invalid.
  /// Returns influencer name on success.
  Future<String> applyReferralCode(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) throw Exception('أدخل كود الإحالة');

    final res = await _client.rpc(
      'apply_referral_code',
      params: {'p_code': trimmed},
    );

    if (res is! Map<String, dynamic>) {
      throw Exception('استجابة غير متوقعة');
    }
    final ok = res['ok'] as bool? ?? false;
    if (!ok) {
      final err = res['error'] as String? ?? 'فشل تطبيق الكود';
      throw Exception(err);
    }
    return res['influencer_name'] as String? ?? 'تم';
  }

  /// Get current user's referral (code_used, referred_at). Null if none.
  Future<Map<String, dynamic>?> getUserReferral() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final row = await _client
          .from('user_referrals')
          .select('code_used, referred_at')
          .eq('user_id', uid)
          .maybeSingle();
      return row;
    } catch (_) {
      return null;
    }
  }
}
