// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banner_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BannerModel _$BannerModelFromJson(Map<String, dynamic> json) => BannerModel(
  id: json['id'] as String,
  imageUrl: json['image_url'] as String,
  videoUrl: json['video_url'] as String?,
  title: json['title'] as String?,
  linkUrl: json['link_url'] as String?,
  orderIndex: (json['order_index'] as num).toInt(),
  isActive: json['is_active'] as bool,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$BannerModelToJson(BannerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'image_url': instance.imageUrl,
      'video_url': instance.videoUrl,
      'title': instance.title,
      'link_url': instance.linkUrl,
      'order_index': instance.orderIndex,
      'is_active': instance.isActive,
      'created_at': instance.createdAt?.toIso8601String(),
    };
