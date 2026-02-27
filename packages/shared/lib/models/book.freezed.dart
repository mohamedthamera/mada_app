// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'book.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Book _$BookFromJson(Map<String, dynamic> json) {
  return _Book.fromJson(json);
}

/// @nodoc
mixin _$Book {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get author => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  String? get language => throw _privateConstructorUsedError;
  int? get pages => throw _privateConstructorUsedError;
  @JsonKey(name: 'cover_url')
  String? get coverUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'cover_path')
  String? get coverPath => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_url')
  String? get fileUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_path')
  String? get filePath => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_type')
  String get fileType => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_size_bytes')
  int? get fileSizeBytes => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_published')
  bool get isPublished => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_featured')
  bool get isFeatured => throw _privateConstructorUsedError;
  @JsonKey(name: 'sort_order')
  int get sortOrder => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_by')
  String? get createdBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Book to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Book
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookCopyWith<Book> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookCopyWith<$Res> {
  factory $BookCopyWith(Book value, $Res Function(Book) then) =
      _$BookCopyWithImpl<$Res, Book>;
  @useResult
  $Res call({
    String id,
    String title,
    String? description,
    String? author,
    String? category,
    String? language,
    int? pages,
    @JsonKey(name: 'cover_url') String? coverUrl,
    @JsonKey(name: 'cover_path') String? coverPath,
    @JsonKey(name: 'file_url') String? fileUrl,
    @JsonKey(name: 'file_path') String? filePath,
    @JsonKey(name: 'file_type') String fileType,
    @JsonKey(name: 'file_size_bytes') int? fileSizeBytes,
    @JsonKey(name: 'is_published') bool isPublished,
    @JsonKey(name: 'is_featured') bool isFeatured,
    @JsonKey(name: 'sort_order') int sortOrder,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime updatedAt,
  });
}

/// @nodoc
class _$BookCopyWithImpl<$Res, $Val extends Book>
    implements $BookCopyWith<$Res> {
  _$BookCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Book
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? author = freezed,
    Object? category = freezed,
    Object? language = freezed,
    Object? pages = freezed,
    Object? coverUrl = freezed,
    Object? coverPath = freezed,
    Object? fileUrl = freezed,
    Object? filePath = freezed,
    Object? fileType = null,
    Object? fileSizeBytes = freezed,
    Object? isPublished = null,
    Object? isFeatured = null,
    Object? sortOrder = null,
    Object? createdBy = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            author: freezed == author
                ? _value.author
                : author // ignore: cast_nullable_to_non_nullable
                      as String?,
            category: freezed == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String?,
            language: freezed == language
                ? _value.language
                : language // ignore: cast_nullable_to_non_nullable
                      as String?,
            pages: freezed == pages
                ? _value.pages
                : pages // ignore: cast_nullable_to_non_nullable
                      as int?,
            coverUrl: freezed == coverUrl
                ? _value.coverUrl
                : coverUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            coverPath: freezed == coverPath
                ? _value.coverPath
                : coverPath // ignore: cast_nullable_to_non_nullable
                      as String?,
            fileUrl: freezed == fileUrl
                ? _value.fileUrl
                : fileUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            filePath: freezed == filePath
                ? _value.filePath
                : filePath // ignore: cast_nullable_to_non_nullable
                      as String?,
            fileType: null == fileType
                ? _value.fileType
                : fileType // ignore: cast_nullable_to_non_nullable
                      as String,
            fileSizeBytes: freezed == fileSizeBytes
                ? _value.fileSizeBytes
                : fileSizeBytes // ignore: cast_nullable_to_non_nullable
                      as int?,
            isPublished: null == isPublished
                ? _value.isPublished
                : isPublished // ignore: cast_nullable_to_non_nullable
                      as bool,
            isFeatured: null == isFeatured
                ? _value.isFeatured
                : isFeatured // ignore: cast_nullable_to_non_nullable
                      as bool,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
            createdBy: freezed == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BookImplCopyWith<$Res> implements $BookCopyWith<$Res> {
  factory _$$BookImplCopyWith(
    _$BookImpl value,
    $Res Function(_$BookImpl) then,
  ) = __$$BookImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String? description,
    String? author,
    String? category,
    String? language,
    int? pages,
    @JsonKey(name: 'cover_url') String? coverUrl,
    @JsonKey(name: 'cover_path') String? coverPath,
    @JsonKey(name: 'file_url') String? fileUrl,
    @JsonKey(name: 'file_path') String? filePath,
    @JsonKey(name: 'file_type') String fileType,
    @JsonKey(name: 'file_size_bytes') int? fileSizeBytes,
    @JsonKey(name: 'is_published') bool isPublished,
    @JsonKey(name: 'is_featured') bool isFeatured,
    @JsonKey(name: 'sort_order') int sortOrder,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime updatedAt,
  });
}

/// @nodoc
class __$$BookImplCopyWithImpl<$Res>
    extends _$BookCopyWithImpl<$Res, _$BookImpl>
    implements _$$BookImplCopyWith<$Res> {
  __$$BookImplCopyWithImpl(_$BookImpl _value, $Res Function(_$BookImpl) _then)
    : super(_value, _then);

  /// Create a copy of Book
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? author = freezed,
    Object? category = freezed,
    Object? language = freezed,
    Object? pages = freezed,
    Object? coverUrl = freezed,
    Object? coverPath = freezed,
    Object? fileUrl = freezed,
    Object? filePath = freezed,
    Object? fileType = null,
    Object? fileSizeBytes = freezed,
    Object? isPublished = null,
    Object? isFeatured = null,
    Object? sortOrder = null,
    Object? createdBy = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$BookImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        author: freezed == author
            ? _value.author
            : author // ignore: cast_nullable_to_non_nullable
                  as String?,
        category: freezed == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String?,
        language: freezed == language
            ? _value.language
            : language // ignore: cast_nullable_to_non_nullable
                  as String?,
        pages: freezed == pages
            ? _value.pages
            : pages // ignore: cast_nullable_to_non_nullable
                  as int?,
        coverUrl: freezed == coverUrl
            ? _value.coverUrl
            : coverUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        coverPath: freezed == coverPath
            ? _value.coverPath
            : coverPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        fileUrl: freezed == fileUrl
            ? _value.fileUrl
            : fileUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        filePath: freezed == filePath
            ? _value.filePath
            : filePath // ignore: cast_nullable_to_non_nullable
                  as String?,
        fileType: null == fileType
            ? _value.fileType
            : fileType // ignore: cast_nullable_to_non_nullable
                  as String,
        fileSizeBytes: freezed == fileSizeBytes
            ? _value.fileSizeBytes
            : fileSizeBytes // ignore: cast_nullable_to_non_nullable
                  as int?,
        isPublished: null == isPublished
            ? _value.isPublished
            : isPublished // ignore: cast_nullable_to_non_nullable
                  as bool,
        isFeatured: null == isFeatured
            ? _value.isFeatured
            : isFeatured // ignore: cast_nullable_to_non_nullable
                  as bool,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        createdBy: freezed == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BookImpl implements _Book {
  const _$BookImpl({
    required this.id,
    required this.title,
    this.description,
    this.author,
    this.category,
    this.language,
    this.pages,
    @JsonKey(name: 'cover_url') this.coverUrl,
    @JsonKey(name: 'cover_path') this.coverPath,
    @JsonKey(name: 'file_url') this.fileUrl,
    @JsonKey(name: 'file_path') this.filePath,
    @JsonKey(name: 'file_type') required this.fileType,
    @JsonKey(name: 'file_size_bytes') this.fileSizeBytes,
    @JsonKey(name: 'is_published') this.isPublished = false,
    @JsonKey(name: 'is_featured') this.isFeatured = false,
    @JsonKey(name: 'sort_order') this.sortOrder = 0,
    @JsonKey(name: 'created_by') this.createdBy,
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'updated_at') required this.updatedAt,
  });

  factory _$BookImpl.fromJson(Map<String, dynamic> json) =>
      _$$BookImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String? description;
  @override
  final String? author;
  @override
  final String? category;
  @override
  final String? language;
  @override
  final int? pages;
  @override
  @JsonKey(name: 'cover_url')
  final String? coverUrl;
  @override
  @JsonKey(name: 'cover_path')
  final String? coverPath;
  @override
  @JsonKey(name: 'file_url')
  final String? fileUrl;
  @override
  @JsonKey(name: 'file_path')
  final String? filePath;
  @override
  @JsonKey(name: 'file_type')
  final String fileType;
  @override
  @JsonKey(name: 'file_size_bytes')
  final int? fileSizeBytes;
  @override
  @JsonKey(name: 'is_published')
  final bool isPublished;
  @override
  @JsonKey(name: 'is_featured')
  final bool isFeatured;
  @override
  @JsonKey(name: 'sort_order')
  final int sortOrder;
  @override
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Book(id: $id, title: $title, description: $description, author: $author, category: $category, language: $language, pages: $pages, coverUrl: $coverUrl, coverPath: $coverPath, fileUrl: $fileUrl, filePath: $filePath, fileType: $fileType, fileSizeBytes: $fileSizeBytes, isPublished: $isPublished, isFeatured: $isFeatured, sortOrder: $sortOrder, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.pages, pages) || other.pages == pages) &&
            (identical(other.coverUrl, coverUrl) ||
                other.coverUrl == coverUrl) &&
            (identical(other.coverPath, coverPath) ||
                other.coverPath == coverPath) &&
            (identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.fileType, fileType) ||
                other.fileType == fileType) &&
            (identical(other.fileSizeBytes, fileSizeBytes) ||
                other.fileSizeBytes == fileSizeBytes) &&
            (identical(other.isPublished, isPublished) ||
                other.isPublished == isPublished) &&
            (identical(other.isFeatured, isFeatured) ||
                other.isFeatured == isFeatured) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    title,
    description,
    author,
    category,
    language,
    pages,
    coverUrl,
    coverPath,
    fileUrl,
    filePath,
    fileType,
    fileSizeBytes,
    isPublished,
    isFeatured,
    sortOrder,
    createdBy,
    createdAt,
    updatedAt,
  ]);

  /// Create a copy of Book
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookImplCopyWith<_$BookImpl> get copyWith =>
      __$$BookImplCopyWithImpl<_$BookImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BookImplToJson(this);
  }
}

abstract class _Book implements Book {
  const factory _Book({
    required final String id,
    required final String title,
    final String? description,
    final String? author,
    final String? category,
    final String? language,
    final int? pages,
    @JsonKey(name: 'cover_url') final String? coverUrl,
    @JsonKey(name: 'cover_path') final String? coverPath,
    @JsonKey(name: 'file_url') final String? fileUrl,
    @JsonKey(name: 'file_path') final String? filePath,
    @JsonKey(name: 'file_type') required final String fileType,
    @JsonKey(name: 'file_size_bytes') final int? fileSizeBytes,
    @JsonKey(name: 'is_published') final bool isPublished,
    @JsonKey(name: 'is_featured') final bool isFeatured,
    @JsonKey(name: 'sort_order') final int sortOrder,
    @JsonKey(name: 'created_by') final String? createdBy,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
    @JsonKey(name: 'updated_at') required final DateTime updatedAt,
  }) = _$BookImpl;

  factory _Book.fromJson(Map<String, dynamic> json) = _$BookImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String? get description;
  @override
  String? get author;
  @override
  String? get category;
  @override
  String? get language;
  @override
  int? get pages;
  @override
  @JsonKey(name: 'cover_url')
  String? get coverUrl;
  @override
  @JsonKey(name: 'cover_path')
  String? get coverPath;
  @override
  @JsonKey(name: 'file_url')
  String? get fileUrl;
  @override
  @JsonKey(name: 'file_path')
  String? get filePath;
  @override
  @JsonKey(name: 'file_type')
  String get fileType;
  @override
  @JsonKey(name: 'file_size_bytes')
  int? get fileSizeBytes;
  @override
  @JsonKey(name: 'is_published')
  bool get isPublished;
  @override
  @JsonKey(name: 'is_featured')
  bool get isFeatured;
  @override
  @JsonKey(name: 'sort_order')
  int get sortOrder;
  @override
  @JsonKey(name: 'created_by')
  String? get createdBy;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;

  /// Create a copy of Book
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookImplCopyWith<_$BookImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
