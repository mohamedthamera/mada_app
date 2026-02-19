import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/lesson_repository.dart';

final lessonsProvider = FutureProvider.family((ref, String courseId) {
  return ref.read(lessonRepositoryProvider).fetchLessons(courseId);
});

final lessonProvider = FutureProvider.family((ref, String lessonId) {
  return ref.read(lessonRepositoryProvider).fetchLessonById(lessonId);
});

