import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(SupabaseClientFactory.client),
);

class NotificationsRepository {
  NotificationsRepository(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> getAllUsersWithTokens() async {
    final res = await _client
        .from('profiles')
        .select('id, fcm_token')
        .not('fcm_token', 'is', null)
        .neq('fcm_token', '');

    return res
        .map(
          (row) => {
            'id': row['id'] as String,
            'fcm_token': row['fcm_token'] as String,
          },
        )
        .toList();
  }

  Future<int> sendNotificationToAll({
    required String title,
    required String body,
  }) async {
    final users = await getAllUsersWithTokens();

    if (users.isEmpty) {
      return 0;
    }

    int successCount = 0;

    for (final user in users) {
      final token = user['fcm_token'] as String;
      try {
        await _client.functions.invoke(
          'send-notification',
          body: {'token': token, 'title': title, 'body': body},
        );
        successCount++;
      } catch (e) {
        continue;
      }
    }

    return successCount;
  }

  Future<SendNotificationResult> sendNotificationToAllBatched({
    required String title,
    required String body,
  }) async {
    final users = await getAllUsersWithTokens();

    if (users.isEmpty) {
      return SendNotificationResult(
        success: true,
        totalUsers: 0,
        successCount: 0,
        failedCount: 0,
      );
    }

    final tokens = users.map((u) => u['fcm_token'] as String).toList();

    try {
      await _client.functions.invoke(
        'send-notification',
        body: {'tokens': tokens, 'title': title, 'body': body},
      );

      return SendNotificationResult(
        success: true,
        totalUsers: tokens.length,
        successCount: tokens.length,
        failedCount: 0,
      );
    } catch (e) {
      return SendNotificationResult(
        success: false,
        totalUsers: tokens.length,
        successCount: 0,
        failedCount: tokens.length,
        error: e.toString(),
      );
    }
  }
}

class SendNotificationResult {
  final bool success;
  final int totalUsers;
  final int successCount;
  final int failedCount;
  final String? error;

  SendNotificationResult({
    required this.success,
    required this.totalUsers,
    required this.successCount,
    required this.failedCount,
    this.error,
  });
}
