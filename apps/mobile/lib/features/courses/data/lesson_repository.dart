import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../../app/di.dart';

final lessonRepositoryProvider = Provider<LessonRepository>(
  (ref) => LessonRepository(ref.read(supabaseClientProvider)),
);

class LessonRepository {
  LessonRepository(this._client);

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

  Future<Lesson> fetchLessonById(String id) async {
    final response =
        await _client.from('lessons').select().eq('id', id).single();
    return Lesson.fromJson(_mapLesson(response as Map<String, dynamic>));
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
      'textFileUrls':
          (json['text_file_urls'] as List<dynamic>?)?.cast<String>() ?? [],
      'textFileNames':
          (json['text_file_names'] as List<dynamic>?)?.cast<String>() ?? [],
    };
  }
}

