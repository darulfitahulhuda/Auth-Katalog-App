import 'package:auth_katalog_app/core/utils/typedef.dart';
import 'package:auth_katalog_app/features/auth/domain/entity/user_entity.dart';

/// Abstract data-access contract for auth operations. Implementations live in
/// the data layer; the domain knows nothing about Dio or storage.
abstract interface class AuthRepository {
  /// Logs a user in with username/password. Returns the authenticated user
  /// on success; tokens are persisted by the implementation.
  FutureData<UserEntity> login({
    required String username,
    required String password,
  });

  /// Invalidates the current session (clears tokens on refresh failure).
  Future<void> logout();

  /// Fetches the authenticated user's profile. Requires a valid access token.
  FutureData<UserEntity> getProfile();

  /// Returns [true] when a valid session exists locally, without hitting the
  /// network (drives auto-login on app launch).
  Future<bool> checkAuthStatus();
}