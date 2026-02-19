import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../offline/data/offline_repository.dart';
import '../../../app/di.dart';

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(
    ref.read(supabaseClientProvider),
    ref.read(offlineRepositoryProvider),
  ),
);

final progressStatsProvider = FutureProvider<ProgressStats>((ref) async {
  final client = ref.read(supabaseClientProvider);
  final userId = client.auth.currentUser?.id ?? '';
  return ref.read(progressRepositoryProvider).getProgressStats(userId);
});

class ProgressRepository {
  ProgressRepository(this._client, this._offline);

  final dynamic _client;
  final OfflineRepository _offline;

  Future<void> saveProgress({
    required String userId,
    required String courseId,
    required String lessonId,
    required double progressPercent,
    required int watchedSeconds,
  }) async {
    await _offline.saveProgress(courseId, progressPercent);
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;

    await _client.from('progress').upsert({
      'user_id': userId,
      'course_id': courseId,
      'lesson_id': lessonId,
      'progress_percent': progressPercent,
      'watched_seconds': watchedSeconds,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> syncAll(String userId) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;
    final progressMap = _offline.getAllProgress();
    for (final entry in progressMap.entries) {
      await _client.from('progress').upsert({
        'user_id': userId,
        'course_id': entry.key,
        'lesson_id': '',
        'progress_percent': entry.value,
        'watched_seconds': 0,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  /// عدد الدروس المكتملة (نسبة المشاهدة >= 99%) وعدد الدورات التي فيها تقدم.
  Future<ProgressStats> getProgressStats(String userId) async {
    if (userId.isEmpty) return ProgressStats(lessonsCompleted: 0, coursesWithProgress: 0);
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        final offlineMap = _offline.getAllProgress();
        final coursesWithProgress = offlineMap.length;
        final lessonsCompleted = offlineMap.values.where((p) => p >= 99).length;
        return ProgressStats(lessonsCompleted: lessonsCompleted, coursesWithProgress: coursesWithProgress);
      }
      final res = await _client
          .from('progress')
          .select('course_id, lesson_id, progress_percent')
          .eq('user_id', userId);
      final list = res as List;
      if (list.isEmpty) return const ProgressStats(lessonsCompleted: 0, coursesWithProgress: 0);
      int lessonsCompleted = 0;
      final courseIds = <String>{};
      for (final row in list) {
        final map = row as Map<String, dynamic>;
        final percent = (map['progress_percent'] as num?)?.toDouble() ?? 0.0;
        final courseId = map['course_id']?.toString() ?? '';
        if (courseId.isNotEmpty) courseIds.add(courseId);
        if (percent >= 99) lessonsCompleted++;
      }
      return ProgressStats(lessonsCompleted: lessonsCompleted, coursesWithProgress: courseIds.length);
    } catch (_) {
      final offlineMap = _offline.getAllProgress();
      final coursesWithProgress = offlineMap.length;
      final lessonsCompleted = offlineMap.values.where((p) => p >= 99).length;
      return ProgressStats(lessonsCompleted: lessonsCompleted, coursesWithProgress: coursesWithProgress);
    }
  }
}

class ProgressStats {
  const ProgressStats({required this.lessonsCompleted, required this.coursesWithProgress});

  final int lessonsCompleted;
  final int coursesWithProgress;
}

