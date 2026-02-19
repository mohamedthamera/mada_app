import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../../app/di.dart';

final adminLessonRepositoryProvider = Provider<AdminLessonRepository>(
  (ref) => AdminLessonRepository(ref.read(supabaseClientProvider)),
);

class AdminLessonRepository {
  AdminLessonRepository(this._client);
  final dynamic _client;

  Future<List<Lesson>> fetchLessons(String courseId) async {
    final response = await _client
        .from('lessons')
        .select()
        .eq('course_id', courseId)
        .order('order_index');
    return (response as List)
        .map((e) => Lesson.fromJson(_mapLesson(e as Map<String, dynamic>)))
        .toList();
  }

  Future<void> insertLesson({
    required String courseId,
    required String titleAr,
    required String titleEn,
    required String videoUrl,
    required int durationSec,
    required int orderIndex,
    bool isFree = false,
    List<String> textFileUrls = const [],
    List<String> textFileNames = const [],
  }) async {
    await _client.from('lessons').insert({
      'course_id': courseId,
      'title': titleAr, // عمود قديم في الجدول (مطلوب)
      'title_ar': titleAr,
      'title_en': titleEn,
      'video_url': videoUrl,
      'duration_sec': durationSec,
      'order_index': orderIndex,
      'is_free': isFree,
      'text_file_urls': textFileUrls,
      'text_file_names': textFileNames,
    });
  }

  Future<void> updateLessonFiles({
    required String lessonId,
    required List<String> textFileUrls,
    required List<String> textFileNames,
  }) async {
    await _client.from('lessons').update({
      'text_file_urls': textFileUrls,
      'text_file_names': textFileNames,
    }).eq('id', lessonId);
  }

  Map<String, dynamic> _mapLesson(Map<String, dynamic> json) {
    return {
      'id': json['id'] as String,
      'courseId': json['course_id'] as String,
      'titleAr': json['title_ar'] as String,
      'titleEn': json['title_en'] as String,
      'videoUrl': json['video_url'] as String,
      'durationSec': (json['duration_sec'] as num).toInt(),
      'orderIndex': (json['order_index'] as num).toInt(),
      'isFree': (json['is_free'] as bool?) ?? false,
      'textFileUrls': (json['text_file_urls'] as List<dynamic>?)?.cast<String>() ?? [],
      'textFileNames': (json['text_file_names'] as List<dynamic>?)?.cast<String>() ?? [],
    };
  }
}
