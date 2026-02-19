import 'package:freezed_annotation/freezed_annotation.dart';

part 'banner_model.freezed.dart';
part 'banner_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
@freezed
class BannerModel with _$BannerModel {
  const factory BannerModel({
    required String id,
    required String imageUrl,
    String? videoUrl,
    String? title,
    String? linkUrl,
    @Default(0) int orderIndex,
    @Default(true) bool isActive,
    DateTime? createdAt,
  }) = _BannerModel;

  factory BannerModel.fromJson(Map<String, dynamic> json) =>
      _$BannerModelFromJson(json);
}
