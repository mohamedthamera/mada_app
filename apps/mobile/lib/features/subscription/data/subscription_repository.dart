import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/di.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(ref.read(supabaseClientProvider)),
);

class SubscriptionRepository {
  SubscriptionRepository(this._client);
  final dynamic _client;

  /// يعيد true إذا كان المستخدم مشتركاً: إما اشتراك مدفوع (جدول subscriptions)
  /// أو اشتراك مدى الحياة عبر كود (user_subscriptions.is_lifetime) أو عبر IAP (entitlements.lifetime_access).
  Future<bool> hasActiveSubscription(String userId) async {
    if (userId.isEmpty) return false;
    // 1) التحقق من اشتراك IAP مدى الحياة (جدول entitlements)
    final entitlementRes = await _client
        .from('entitlements')
        .select('lifetime_access')
        .eq('user_id', userId)
        .maybeSingle();
    if (entitlementRes != null && entitlementRes['lifetime_access'] == true) {
      return true;
    }
    // 2) التحقق من اشتراك مدى الحياة (أكواد التفعيل)
    final lifetimeRes = await _client
        .from('user_subscriptions')
        .select('is_lifetime')
        .eq('user_id', userId)
        .maybeSingle();
    final lifetime = lifetimeRes != null && (lifetimeRes['is_lifetime'] == true);
    if (lifetime) return true;
    // 3) التحقق من اشتراك مدفوع (جدول subscriptions)
    final res = await _client
        .from('subscriptions')
        .select('status, expires_at')
        .eq('user_id', userId)
        .eq('status', 'active')
        .order('started_at', ascending: false)
        .limit(1);
    final list = res as List;
    if (list.isEmpty) return false;
    final row = list.first as Map<String, dynamic>;
    final expiresAt = row['expires_at'] as String?;
    if (expiresAt == null) return true;
    final dt = DateTime.parse(expiresAt);
    return dt.isAfter(DateTime.now());
  }
}

