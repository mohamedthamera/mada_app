import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_subscriptions_repository.dart';

/// قائمة المستخدمين المشتركين في المنصة (من user_subscriptions)
final adminSubscriptionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminSubscriptionsRepositoryProvider).fetchSubscribedUsers();
});
