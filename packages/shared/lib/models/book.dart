import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';
part 'book.g.dart';

@Freezed(fromJson: true, toJson: true)
class Book with _$Book {
  const factory Book({
    required String id,
    required String title,
    String? description,
    String? author,
    String? category,
    String? language,
    int? pages,
    @JsonKey(name: 'cover_url') String? coverUrl,
    @JsonKey(name: 'cover_path') String? coverPath,
    @JsonKey(name: 'file_url') String? fileUrl,
    @JsonKey(name: 'file_path') String? filePath,
    @JsonKey(name: 'file_type') required String fileType,
    @JsonKey(name: 'file_size_bytes') int? fileSizeBytes,
    @JsonKey(name: 'is_published') @Default(false) bool isPublished,
    @JsonKey(name: 'is_featured') @Default(false) bool isFeatured,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Book;

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
}
