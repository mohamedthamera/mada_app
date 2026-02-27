// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BookImpl _$$BookImplFromJson(Map<String, dynamic> json) => _$BookImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  author: json['author'] as String?,
  category: json['category'] as String?,
  language: json['language'] as String?,
  pages: (json['pages'] as num?)?.toInt(),
  coverUrl: json['cover_url'] as String?,
  coverPath: json['cover_path'] as String?,
  fileUrl: json['file_url'] as String?,
  filePath: json['file_path'] as String?,
  fileType: json['file_type'] as String,
  fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt(),
  isPublished: json['is_published'] as bool? ?? false,
  isFeatured: json['is_featured'] as bool? ?? false,
  sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
  createdBy: json['created_by'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$$BookImplToJson(_$BookImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'author': instance.author,
      'category': instance.category,
      'language': instance.language,
      'pages': instance.pages,
      'cover_url': instance.coverUrl,
      'cover_path': instance.coverPath,
      'file_url': instance.fileUrl,
      'file_path': instance.filePath,
      'file_type': instance.fileType,
      'file_size_bytes': instance.fileSizeBytes,
      'is_published': instance.isPublished,
      'is_featured': instance.isFeatured,
      'sort_order': instance.sortOrder,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
