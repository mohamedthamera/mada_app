// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discussion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Discussion _$DiscussionFromJson(Map<String, dynamic> json) {
  return _Discussion.fromJson(json);
}

/// @nodoc
mixin _$Discussion {
  String get id => throw _privateConstructorUsedError;
  String get courseId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Discussion to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Discussion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiscussionCopyWith<Discussion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiscussionCopyWith<$Res> {
  factory $DiscussionCopyWith(
    Discussion value,
    $Res Function(Discussion) then,
  ) = _$DiscussionCopyWithImpl<$Res, Discussion>;
  @useResult
  $Res call({
    String id,
    String courseId,
    String userId,
    String title,
    String body,
    DateTime createdAt,
  });
}

/// @nodoc
class _$DiscussionCopyWithImpl<$Res, $Val extends Discussion>
    implements $DiscussionCopyWith<$Res> {
  _$DiscussionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Discussion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? courseId = null,
    Object? userId = null,
    Object? title = null,
    Object? body = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            courseId: null == courseId
                ? _value.courseId
                : courseId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            body: null == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DiscussionImplCopyWith<$Res>
    implements $DiscussionCopyWith<$Res> {
  factory _$$DiscussionImplCopyWith(
    _$DiscussionImpl value,
    $Res Function(_$DiscussionImpl) then,
  ) = __$$DiscussionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String courseId,
    String userId,
    String title,
    String body,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$DiscussionImplCopyWithImpl<$Res>
    extends _$DiscussionCopyWithImpl<$Res, _$DiscussionImpl>
    implements _$$DiscussionImplCopyWith<$Res> {
  __$$DiscussionImplCopyWithImpl(
    _$DiscussionImpl _value,
    $Res Function(_$DiscussionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Discussion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? courseId = null,
    Object? userId = null,
    Object? title = null,
    Object? body = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$DiscussionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        courseId: null == courseId
            ? _value.courseId
            : courseId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        body: null == body
            ? _value.body
            : body // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DiscussionImpl implements _Discussion {
  const _$DiscussionImpl({
    required this.id,
    required this.courseId,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory _$DiscussionImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiscussionImplFromJson(json);

  @override
  final String id;
  @override
  final String courseId;
  @override
  final String userId;
  @override
  final String title;
  @override
  final String body;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Discussion(id: $id, courseId: $courseId, userId: $userId, title: $title, body: $body, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiscussionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.courseId, courseId) ||
                other.courseId == courseId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, courseId, userId, title, body, createdAt);

  /// Create a copy of Discussion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiscussionImplCopyWith<_$DiscussionImpl> get copyWith =>
      __$$DiscussionImplCopyWithImpl<_$DiscussionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DiscussionImplToJson(this);
  }
}

abstract class _Discussion implements Discussion {
  const factory _Discussion({
    required final String id,
    required final String courseId,
    required final String userId,
    required final String title,
    required final String body,
    required final DateTime createdAt,
  }) = _$DiscussionImpl;

  factory _Discussion.fromJson(Map<String, dynamic> json) =
      _$DiscussionImpl.fromJson;

  @override
  String get id;
  @override
  String get courseId;
  @override
  String get userId;
  @override
  String get title;
  @override
  String get body;
  @override
  DateTime get createdAt;

  /// Create a copy of Discussion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiscussionImplCopyWith<_$DiscussionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
