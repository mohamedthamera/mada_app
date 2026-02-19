// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CourseImpl _$$CourseImplFromJson(Map<String, dynamic> json) => _$CourseImpl(
  id: json['id'] as String,
  titleAr: json['titleAr'] as String,
  titleEn: json['titleEn'] as String,
  descAr: json['descAr'] as String,
  descEn: json['descEn'] as String,
  categoryId: json['categoryId'] as String,
  level: json['level'] as String,
  thumbnailUrl: json['thumbnailUrl'] as String,
  ratingAvg: (json['ratingAvg'] as num).toDouble(),
  ratingCount: (json['ratingCount'] as num).toInt(),
);

Map<String, dynamic> _$$CourseImplToJson(_$CourseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titleAr': instance.titleAr,
      'titleEn': instance.titleEn,
      'descAr': instance.descAr,
      'descEn': instance.descEn,
      'categoryId': instance.categoryId,
      'level': instance.level,
      'thumbnailUrl': instance.thumbnailUrl,
      'ratingAvg': instance.ratingAvg,
      'ratingCount': instance.ratingCount,
    };
