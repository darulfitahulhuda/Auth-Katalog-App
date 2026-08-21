import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';

/// Pure domain entity for the authenticated user. Freezed gives value
/// equality + copyWith, still fully domain-safe (no JSON, no Flutter).
@freezed
abstract class UserEntity with _$UserEntity {
  const UserEntity._();

  const factory UserEntity({
    required int id,
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String gender,
    required String image,
  }) = _UserEntity;

  String get displayName => '$firstName $lastName'.trim();
}