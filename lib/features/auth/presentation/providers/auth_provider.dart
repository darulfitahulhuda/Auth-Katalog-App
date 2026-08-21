import 'dart:async';

import 'package:auth_katalog_app/core/error/failures.dart';
import 'package:auth_katalog_app/core/di/providers.dart';
import 'package:auth_katalog_app/core/usecase/usecase.dart';
import 'package:auth_katalog_app/features/auth/domain/usecase/check_auth_status_usecase.dart';
import 'package:auth_katalog_app/features/auth/domain/usecase/get_profile_usecase.dart';
import 'package:auth_katalog_app/features/auth/domain/usecase/login_usecase.dart';
import 'package:auth_katalog_app/features/auth/domain/usecase/logout_usecase.dart';
import 'package:auth_katalog_app/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Orchestrates auth flows as an [AsyncNotifier]: auto-login check on launch,
/// login, logout, and forced sign-out when the refresh token expires.
/// The state is an [AsyncValue] wrapping the sealed [AuthState], so the UI can
/// react to loading/error/data. UI never talks to Dio/repositories directly.
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  FutureOr<AuthState> build() {
    // Kick off the session check once, the first time the provider loads.
    // `build` may return the initial value immediately; the async check runs
    // in the background and flips [state] when it completes.
    Future.microtask(checkAuthStatus);
    return const AuthInitial();
  }

  LoginUseCase get _login => ref.read(loginUseCaseProvider);
  LogoutUseCase get _logout => ref.read(logoutUseCaseProvider);
  GetProfileUseCase get _getProfile => ref.read(getProfileUseCaseProvider);
  CheckAuthStatusUseCase get _check => ref.read(checkAuthStatusUseCaseProvider);

  /// Checks for a persisted session on launch → AuthAuthenticated or Unauth.
  Future<void> checkAuthStatus() async {
    if (state.value is AuthAuthenticated) return;

    state = const AsyncLoading();
    final result = await _check(const NoParams());
    if (state is! AsyncLoading) return; // superseded

    result.fold(
      (_) => state = const AsyncData(AuthUnauthenticated()),
      (hasSession) async {
        if (!hasSession) {
          state = const AsyncData(AuthUnauthenticated());
          return;
        }
        final profile = await _getProfile(const NoParams());
        if (state is! AsyncLoading) return;
        profile.fold(
          (_) => state = const AsyncData(AuthUnauthenticated()),
          (user) => state = AsyncData(AuthAuthenticated(user)),
        );
      },
    );
  }

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
      (failure) => state = AsyncData(AuthError(_messageText(failure))),
      (user) => state = AsyncData(AuthAuthenticated(user)),
    );
  }

  /// Logs out locally and clears stored tokens.
  Future<void> logout() async {
    await _logout(const NoParams());
    state = const AsyncData(AuthUnauthenticated());
  }

  /// Called by the auth interceptor when refresh fails: clear state and
  /// land back on the login screen.
  Future<void> onSessionExpired() async {
    await _logout(const NoParams());
    state = const AsyncData(AuthUnauthenticated());
  }

  String _messageText(Failure failure) {
    if (failure.message.isNotEmpty) return failure.message;
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}