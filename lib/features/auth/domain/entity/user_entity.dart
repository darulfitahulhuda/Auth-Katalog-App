import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';

/// Lightweight login identity. Holds only what the login response carries;
/// richer profile data (`/auth/me`) lives in the [ProfileEntity] from the
/// profile feature. Freezed gives value equality + copyWith, still fully
/// domain-safe (no JSON, no Flutter).
@freezed
abstract class UserEntity with _$UserEntity {
  const UserEntity._();

  const factory UserEntity({
    required int id,
    required String username,
    required String email,
  }) = _UserEntity;

  /// Marker for an authenticated session whose account details are still
  /// loading (auto-login on cold start). Screens read the actual profile via
  /// the profile feature's provider, so this empty identity is never shown.
  const factory UserEntity.empty() = _UserEntityEmpty;
}