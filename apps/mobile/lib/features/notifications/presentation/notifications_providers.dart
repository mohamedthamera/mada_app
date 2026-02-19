import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../data/notifications_repository.dart';
import '../../../app/di.dart';

final notificationsProvider = FutureProvider<List<NotificationItem>>((ref) {
  final userId = ref.read(supabaseClientProvider).auth.currentUser?.id ?? '';
  if (userId.isEmpty) return Future.value(<NotificationItem>[]);
  return ref.read(notificationsRepositoryProvider).fetchNotifications(userId);
});

