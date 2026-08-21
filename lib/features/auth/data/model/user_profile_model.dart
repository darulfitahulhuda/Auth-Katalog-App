import 'package:auth_katalog_app/features/auth/domain/entity/user_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile_model.freezed.dart';
part 'user_profile_model.g.dart';

/// User profile returned by `GET /auth/me` (and `GET /auth/me` fields).
/// Maps to [UserEntity]; serialization lives only in this data-layer class.
@freezed
abstract class UserProfileModel with _$UserProfileModel {
  const UserProfileModel._();

  const factory UserProfileModel({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'username') required String username,
    @JsonKey(name: 'email') required String email,
    @JsonKey(name: 'firstName') required String firstName,
    @JsonKey(name: 'lastName') required String lastName,
    @JsonKey(name: 'gender') required String gender,
  }) = _UserProfileModel;

  factory UserProfileModel.fromJson(Map<String, Object?> json) =>
      _$UserProfileModelFromJson(json);

  /// Maps to the pure domain entity.
  UserEntity toEntity() => UserEntity(
        id: id,
        username: username,
        email: email,
        firstName: firstName,
        lastName: lastName,
        gender: gender,
      );
}