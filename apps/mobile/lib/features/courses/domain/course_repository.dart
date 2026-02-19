import 'package:shared/shared.dart';

abstract class CourseRepository {
  Future<List<Course>> fetchCourses();
  Future<Course> fetchCourseById(String id);
}

