import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/di.dart';

final adminAnalyticsRepositoryProvider = Provider<AdminAnalyticsRepository>(
  (ref) => AdminAnalyticsRepository(ref.read(supabaseClientProvider)),
);

class AdminAnalyticsRepository {
  AdminAnalyticsRepository(this._client);
  final SupabaseClient _client;

  Future<Map<String, int>> fetchCounts() async {
    final courses = await _count('courses');
    final users = await _count('profiles');
    final enrollments = await _count('enrollments');
    return {
      'courses': courses,
      'users': users,
      'enrollments': enrollments,
    };
  }

  /// معدل الإكمال: نسبة المستخدمين الذين أكملوا دورة (progress >= 100%) من إجمالي الاشتراكات
  Future<double> fetchCompletionRate() async {
    final enrollmentsCount = await _count('enrollments');
    if (enrollmentsCount == 0) return 0.0;
    final list = await _client
        .from('progress')
        .select('id')
        .gte('progress_percent', 100);
    final completed = (list as List).length;
    return (completed / enrollmentsCount * 100).clamp(0.0, 100.0);
  }

  /// عدد الاشتراكات لكل يوم في آخر 30 يوماً (للمخطط)
  Future<List<int>> fetchEnrollmentsPerDayLast30() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    final res = await _client
        .from('enrollments')
        .select('created_at')
        .gte('created_at', start.toIso8601String());
    final list = res as List;
    final byDay = <String, int>{};
    for (var i = 0; i < 30; i++) {
      final d = start.add(Duration(days: i));
      byDay[_dayKey(d)] = 0;
    }
    for (final e in list) {
      final map = e as Map<String, dynamic>;
      final created = map['created_at'] as String?;
      if (created == null) continue;
      final dt = DateTime.parse(created);
      final key = _dayKey(dt);
      if (byDay.containsKey(key)) byDay[key] = (byDay[key] ?? 0) + 1;
    }
    final sorted = byDay.keys.toList()..sort();
    return sorted.map((k) => byDay[k] ?? 0).toList();
  }

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<int> _count(String table) async {
    return await _client.from(table).count(CountOption.exact);
  }

  /// أعداد حقيقية للوحة الأدمن (عبر RPC لتجاوز RLS)
  Future<Map<String, dynamic>> fetchDashboardCounts() async {
    final res = await _client.rpc('admin_dashboard_counts');
    if (res is! Map<String, dynamic>) throw Exception('استجابة غير متوقعة');
    if (res['ok'] != true) {
      throw Exception((res['message'] ?? 'فشل تحميل البيانات').toString());
    }
    return {
      'registered_users': res['registered_users'] is int
          ? res['registered_users'] as int
          : int.tryParse(res['registered_users'].toString()) ?? 0,
      'subscribed_users': res['subscribed_users'] is int
          ? res['subscribed_users'] as int
          : int.tryParse(res['subscribed_users'].toString()) ?? 0,
      'courses': res['courses'] is int
          ? res['courses'] as int
          : int.tryParse(res['courses'].toString()) ?? 0,
      'enrollments': res['enrollments'] is int
          ? res['enrollments'] as int
          : int.tryParse(res['enrollments'].toString()) ?? 0,
      'completion_rate': res['completion_rate'] is num
          ? (res['completion_rate'] as num).toDouble()
          : double.tryParse(res['completion_rate'].toString()) ?? 0.0,
    };
  }
}

