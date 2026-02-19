import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/di.dart';
import '../data/course_repository.dart';

final coursesProvider = FutureProvider((ref) {
  return ref.read(courseRepositoryProvider).fetchCourses();
});

final courseProvider = FutureProvider.family((ref, String id) {
  return ref.read(courseRepositoryProvider).fetchCourseById(id);
});

final courseEnrollmentsCountProvider = FutureProvider.family((ref, String courseId) async {
  final client = ref.read(supabaseClientProvider);
  final response = await client
      .from('enrollments')
      .select()
      .eq('course_id', courseId);
  return (response as List).length;
});

