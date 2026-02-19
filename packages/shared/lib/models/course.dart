import 'package:freezed_annotation/freezed_annotation.dart';

part 'course.freezed.dart';
part 'course.g.dart';

@freezed
class Course with _$Course {
  const factory Course({
    required String id,
    required String titleAr,
    required String titleEn,
    required String descAr,
    required String descEn,
    required String categoryId,
    required String level,
    required String thumbnailUrl,
    required double ratingAvg,
    required int ratingCount,
  }) = _Course;

  factory Course.fromJson(Map<String, dynamic> json) =>
      _$CourseFromJson(json);
}

