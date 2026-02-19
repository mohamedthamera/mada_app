// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProgressImpl _$$ProgressImplFromJson(Map<String, dynamic> json) =>
    _$ProgressImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      courseId: json['courseId'] as String,
      lessonId: json['lessonId'] as String,
      progressPercent: (json['progressPercent'] as num).toDouble(),
      watchedSeconds: (json['watchedSeconds'] as num).toInt(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ProgressImplToJson(_$ProgressImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'courseId': instance.courseId,
      'lessonId': instance.lessonId,
      'progressPercent': instance.progressPercent,
      'watchedSeconds': instance.watchedSeconds,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
