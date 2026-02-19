import 'package:freezed_annotation/freezed_annotation.dart';

part 'lesson.freezed.dart';
part 'lesson.g.dart';

@freezed
class Lesson with _$Lesson {
  const factory Lesson({
    required String id,
    required String courseId,
    required String titleAr,
    required String titleEn,
    required String videoUrl,
    required int durationSec,
    required int orderIndex,
    required bool isFree,
    @Default([]) List<String> textFileUrls,
    @Default([]) List<String> textFileNames,
  }) = _Lesson;

  factory Lesson.fromJson(Map<String, dynamic> json) =>
      _$LessonFromJson(json);
}

