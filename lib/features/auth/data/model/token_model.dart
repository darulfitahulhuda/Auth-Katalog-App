import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_model.freezed.dart';
part 'token_model.g.dart';

/// Tokens returned by `POST /auth/login` and `POST /auth/refresh`.
@freezed
abstract class TokenModel with _$TokenModel {
  const factory TokenModel({
    @JsonKey(name: 'accessToken') required String accessToken,
    @JsonKey(name: 'refreshToken') required String refreshToken,
  }) = _TokenModel;

  factory TokenModel.fromJson(Map<String, Object?> json) =>
      _$TokenModelFromJson(json);
}