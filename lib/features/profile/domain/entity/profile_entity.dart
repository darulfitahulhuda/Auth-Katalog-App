import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_entity.freezed.dart';

/// Pure domain representation of the authenticated user's profile (returned
/// by `GET /auth/me`). Lives in the profile feature, distinct from auth's
/// lightweight [UserEntity]. No JSON — serialize in the data layer only.
@freezed
abstract class ProfileEntity with _$ProfileEntity {
  const ProfileEntity._();

  const factory ProfileEntity({
    required int id,
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String gender,
    @Default('') String image,
  }) = _ProfileEntity;

  /// Convenience display name for the UI (e.g. app bar greeting).
  String get displayName => '$firstName $lastName';
}