import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../subscription/data/subscription_repository.dart';
import '../../../app/di.dart';

final hasActiveSubscriptionProvider = FutureProvider<bool>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final userId = client.auth.currentUser?.id ?? '';
  return ref
      .read(subscriptionRepositoryProvider)
      .hasActiveSubscription(userId);
});

