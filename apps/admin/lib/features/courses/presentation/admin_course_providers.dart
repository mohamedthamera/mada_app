import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mada_admin/features/courses/data/admin_course_repository.dart';

final adminCoursesProvider = FutureProvider((ref) {
  return ref.read(adminCourseRepositoryProvider).fetchCourses();
});

