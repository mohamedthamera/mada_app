import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../../app/di.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.read(supabaseClientProvider)),
);

class NotificationsRepository {
  NotificationsRepository(this._client);
  final dynamic _client;

  Future<List<NotificationItem>> fetchNotifications(String userId) async {
    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => NotificationItem.fromJson(_map(e as Map<String, dynamic>)))
        .toList();
  }

  Future<void> markRead(String id) async {
    await _client.from('notifications').update({
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Map<String, dynamic> _map(Map<String, dynamic> json) {
    return {
      'id': json['id'] as String,
      'userId': json['user_id'] as String,
      'title': json['title'] as String,
      'body': json['body'] as String,
      'type': json['type'] as String,
      'createdAt': DateTime.parse(json['created_at'] as String),
      'readAt': json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
    };
  }
}

