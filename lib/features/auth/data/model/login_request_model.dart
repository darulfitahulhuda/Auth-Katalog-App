import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_request_model.freezed.dart';
part 'login_request_model.g.dart';

/// JSON payload for `POST /auth/login`.
@freezed
abstract class LoginRequestModel with _$LoginRequestModel {
  const factory LoginRequestModel({
    @JsonKey(name: 'username') required String username,
    @JsonKey(name: 'password') required String password,
    @JsonKey(name: 'expiresInMins') @Default(1) int expiresInMins,
  }) = _LoginRequestModel;

  factory LoginRequestModel.fromJson(Map<String, Object?> json) =>
      _$LoginRequestModelFromJson(json);
}