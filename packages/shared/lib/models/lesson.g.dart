// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LessonImpl _$$LessonImplFromJson(Map<String, dynamic> json) => _$LessonImpl(
  id: json['id'] as String,
  courseId: json['courseId'] as String,
  titleAr: json['titleAr'] as String,
  titleEn: json['titleEn'] as String,
  videoUrl: json['videoUrl'] as String,
  durationSec: (json['durationSec'] as num).toInt(),
  orderIndex: (json['orderIndex'] as num).toInt(),
  isFree: json['isFree'] as bool,
  textFileUrls:
      (json['textFileUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  textFileNames:
      (json['textFileNames'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$$LessonImplToJson(_$LessonImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'courseId': instance.courseId,
      'titleAr': instance.titleAr,
      'titleEn': instance.titleEn,
      'videoUrl': instance.videoUrl,
      'durationSec': instance.durationSec,
      'orderIndex': instance.orderIndex,
      'isFree': instance.isFree,
      'textFileUrls': instance.textFileUrls,
      'textFileNames': instance.textFileNames,
    };
