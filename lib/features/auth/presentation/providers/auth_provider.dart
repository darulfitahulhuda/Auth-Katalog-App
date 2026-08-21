import 'dart:async';

import 'package:auth_katalog_app/core/di/providers.dart';
import 'package:auth_katalog_app/core/usecase/usecase.dart';
import 'package:auth_katalog_app/features/auth/domain/entity/user_entity.dart';
import 'package:auth_katalog_app/features/auth/domain/usecase/check_auth_status_usecase.dart';
import 'package:auth_katalog_app/features/auth/domain/usecase/login_usecase.dart';
import 'package:auth_katalog_app/features/auth/domain/usecase/logout_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Orchestrates auth (session) flows as an [AsyncNotifier]: auto-login check
/// on launch, login, logout, and forced sign-out when the refresh token
/// expires. The state is an [AsyncValue] wrapping a lightweight [UserEntity]
/// (null = unauthenticated). Profile detail is read from the profile feature
/// via its own provider; UI never talks to Dio/repositories directly.
class AuthNotifier extends AsyncNotifier<UserEntity?> {
  @override
  Future<UserEntity?> build() async {
    // Session check only — no network. While this future is pending the state
    // stays [AsyncLoading]; the router redirect skips loading so the login
    // screen never flashes on launch.
    try {
      final result = await _check(const NoParams());
      // Resolve fold into a concrete value before returning — fpdart's fold
      // returns FutureOr, and returning a (possibly) Future inside a try
      // triggers `unawaited_return_in_try_block`.
      final session = result.fold<UserEntity?>(
        (_) => null,
        (hasSession) => hasSession ? const UserEntity.empty() : null,
      );
      return session;
    } catch (e) {
      return null;
    }
  }

  LoginUseCase get _login => ref.read(loginUseCaseProvider);
  LogoutUseCase get _logout => ref.read(logoutUseCaseProvider);
  CheckAuthStatusUseCase get _check => ref.read(checkAuthStatusUseCaseProvider);

  /// Logs the user in and stores tokens (via the repository).
  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result = await _login(
      LoginParams(username: username, password: password),
    );
    if (state is! AsyncLoading) return;

    result.fold(
      (failure) => state = AsyncError(failure.message, failure.stackTrace),
      (user) => state = AsyncData(user),
    );
  }

  /// Logs out locally and clears stored tokens.
  Future<void> logout() async {
    await _logout(const NoParams());
    state = const AsyncData(null);
  }

  /// Called by the auth interceptor when refresh fails: clear state and
  /// land back on the login screen.
  Future<void> onSessionExpired() async {
    await _logout(const NoParams());
    state = const AsyncData(null);
  }
}
