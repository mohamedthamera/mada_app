import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../../app/di.dart';

final adminCourseRepositoryProvider = Provider<AdminCourseRepository>(
  (ref) => AdminCourseRepository(ref.read(supabaseClientProvider)),
);

class AdminCourseRepository {
  AdminCourseRepository(this._client);
  final dynamic _client;

  Future<List<Course>> fetchCourses() async {
    final response = await _client
        .from('courses')
        .select()
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => Course.fromJson(_mapCourse(e as Map<String, dynamic>)))
        .toList();
  }

  /// يُرجع id الدورة المُنشأة
  Future<String> insertCourse({
    required String titleAr,
    required String titleEn,
    required String descAr,
    required String descEn,
    required String categoryId,
    required String level,
    required String thumbnailUrl,
    double ratingAvg = 0,
    int ratingCount = 0,
  }) async {
    final res = await _client.from('courses').insert({
      'title_ar': titleAr,
      'title_en': titleEn,
      'desc_ar': descAr,
      'desc_en': descEn,
      'category_id': categoryId,
      'level': level,
      'thumbnail_url': thumbnailUrl,
      'rating_avg': ratingAvg,
      'rating_count': ratingCount,
    }).select('id').single();
    return res['id'] as String;
  }

  Future<void> updateCourse({
    required String id,
    required String titleAr,
    required String titleEn,
    required String descAr,
    required String descEn,
    required String categoryId,
    required String level,
    required String thumbnailUrl,
  }) async {
    await _client.from('courses').update({
      'title_ar': titleAr,
      'title_en': titleEn,
      'desc_ar': descAr,
      'desc_en': descEn,
      'category_id': categoryId,
      'level': level,
      'thumbnail_url': thumbnailUrl,
    }).eq('id', id);
  }

  Future<void> deleteCourse(String id) async {
    await _client.from('courses').delete().eq('id', id);
  }

  Map<String, dynamic> _mapCourse(Map<String, dynamic> json) {
    return {
      'id': json['id'] as String,
      'titleAr': json['title_ar'] as String,
      'titleEn': json['title_en'] as String,
      'descAr': json['desc_ar'] as String,
      'descEn': json['desc_en'] as String,
      'categoryId': json['category_id'] as String,
      'level': json['level'] as String,
      'thumbnailUrl': json['thumbnail_url'] as String,
      'ratingAvg': (json['rating_avg'] as num?)?.toDouble() ?? 0.0,
      'ratingCount': (json['rating_count'] as num?)?.toInt() ?? 0,
    };
  }
}

