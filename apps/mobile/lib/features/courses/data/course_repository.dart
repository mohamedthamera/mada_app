import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../../app/di.dart';
import '../domain/course_repository.dart';

final courseRepositoryProvider = Provider<CourseRepository>(
  (ref) => SupabaseCourseRepository(ref.read(supabaseClientProvider)),
);

class SupabaseCourseRepository implements CourseRepository {
  SupabaseCourseRepository(this._client);

  final dynamic _client;

  @override
  Future<List<Course>> fetchCourses() async {
    final response = await _client
        .from('courses')
        .select()
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => Course.fromJson(_mapCourse(e as Map<String, dynamic>)))
        .toList();
  }

  @override
  Future<Course> fetchCourseById(String id) async {
    final response =
        await _client.from('courses').select().eq('id', id).single();
    return Course.fromJson(_mapCourse(response as Map<String, dynamic>));
  }

  Map<String, dynamic> _mapCourse(Map<String, dynamic> json) {
    final ratingAvg = (json['rating_avg'] as num?)?.toDouble() ?? 0.0;
    return {
      'id': json['id'] as String,
      'titleAr': json['title_ar'] as String,
      'titleEn': json['title_en'] as String,
      'descAr': json['desc_ar'] as String,
      'descEn': json['desc_en'] as String,
      'categoryId': json['category_id'] as String,
      'level': json['level'] as String,
      'thumbnailUrl': json['thumbnail_url'] as String,
      'ratingAvg': ratingAvg < 4 ? 4.0 : ratingAvg,
      'ratingCount': (json['rating_count'] as num?)?.toInt() ?? 0,
    };
  }
}

