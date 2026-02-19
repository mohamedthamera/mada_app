import 'package:freezed_annotation/freezed_annotation.dart';

part 'discussion.freezed.dart';
part 'discussion.g.dart';

@freezed
class Discussion with _$Discussion {
  const factory Discussion({
    required String id,
    required String courseId,
    required String userId,
    required String title,
    required String body,
    required DateTime createdAt,
  }) = _Discussion;

  factory Discussion.fromJson(Map<String, dynamic> json) =>
      _$DiscussionFromJson(json);
}

