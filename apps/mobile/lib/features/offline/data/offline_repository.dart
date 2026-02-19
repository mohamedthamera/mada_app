import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final offlineRepositoryProvider = Provider<OfflineRepository>(
  (ref) => OfflineRepository(),
);

class OfflineRepository {
  static const _progressBox = 'progress_box';
  // Minimal offline downloads placeholders to satisfy UI usage.
  // Storage implementation can be added later if needed.

  Future<void> init() async {
    await Hive.openBox<double>(_progressBox);
  }

  double getProgress(String courseId) {
    final box = Hive.box<double>(_progressBox);
    return box.get(courseId, defaultValue: 0.0) ?? 0.0;
  }

  Future<void> saveProgress(String courseId, double progress) async {
    final box = Hive.box<double>(_progressBox);
    await box.put(courseId, progress);
  }

  Map<String, double> getAllProgress() {
    final box = Hive.box<double>(_progressBox);
    return box.toMap().map((key, value) => MapEntry('$key', value));
  }

  // Offline downloads API required by OfflineScreen
  List<String> getDownloadedLessons() {
    return const <String>[];
  }

  String? getCourseIdForDownload(String lessonId) {
    return null;
    }

  String? getLessonTitle(String lessonId) {
    return null;
  }

  Future<void> removeDownload(String lessonId) async {
    // no-op for now
  }
}
