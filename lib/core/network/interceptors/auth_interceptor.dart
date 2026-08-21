import 'dart:async';

import 'package:auth_katalog_app/features/auth/domain/repositories/token_repository.dart';
import 'package:dio/dio.dart';

/// Injects `Authorization: Bearer <accessToken>` into every protected request
/// and transparently refreshes an expired access token (single-flight) before
/// retrying the original request.
///
/// Isolation rules:
/// - The refresh call uses its own clean [Dio] instance built by
///   [createDioClient] WITHOUT this interceptor, so a 401 during refresh can
///   never recurse.
/// - `/auth/login` and `/auth/refresh` are excluded from 401 handling.
typedef VoidCallback = void Function();

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenRepository tokenRepository,
    required Dio dio,
    VoidCallback? onUnauthorized,
  }) : _tokenRepository = tokenRepository,
       _dio = dio,
       _onUnauthorized = onUnauthorized;

  final TokenRepository _tokenRepository;
  final Dio _dio;
  final VoidCallback? _onUnauthorized;

  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  static const _loginPath = '/auth/login';
  static const _refreshPath = '/auth/refresh';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _tokenRepository.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;

    // Only handle 401s on protected endpoints. Login/refresh failures must
    // propagate to the caller untouched.
    final isHandledEndpoint =
        path.endsWith(_loginPath) || path.endsWith(_refreshPath);
    if (status != 401 || isHandledEndpoint) {
      return handler.next(err);
    }

    // Single-flight lock: the first concurrent 401 triggers refresh; all
    // others wait on the same future.
    if (_isRefreshing) {
      _refreshCompleter!.future.then((newToken) {
        if (newToken != null) {
          _retryOriginalRequest(err.requestOptions, handler);
        } else {
          handler.reject(err);
        }
      });
      return;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    _handleTokenRefresh()
        .then((newToken) {
          _isRefreshing = false;
          _refreshCompleter = null;

          if (newToken != null) {
            _retryOriginalRequest(err.requestOptions, handler);
          } else {
            handler.reject(err);
          }
        })
        .catchError((Object e, StackTrace st) {
          _isRefreshing = false;
          _refreshCompleter = null;
          handler.reject(err);
        });
  }

  /// Calls `/auth/refresh` on an isolated Dio instance, saving new tokens.
  Future<String?> _handleTokenRefresh() async {
    try {
      final refreshToken = await _tokenRepository.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _tokenRepository.clearTokens();
        _onUnauthorized?.call();
        _refreshCompleter!.complete(null);
        return null;
      }

      // Isolated client: clone the main Dio but strip INTERCEPTORS so the
      // refresh request can never recurse into this interceptor. The same
      // [httpClientAdapter] is preserved (real transport, or test mock).
      final isolatedDio = Dio(_dio.options)
        ..httpClientAdapter = _dio.httpClientAdapter;
      final response = await isolatedDio.post<Map<String, dynamic>>(
        _refreshPath,
        data: {'refreshToken': refreshToken},
      );

      final data = response.data;
      final newAccess = data?['accessToken'] as String?;
      final newRefresh = data?['refreshToken'] as String?;
      if (newAccess == null || newRefresh == null) {
        throw DioException.connectionError(
          requestOptions: RequestOptions(path: _refreshPath),
          reason: 'Invalid refresh response',
        );
      }

      await _tokenRepository.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      _refreshCompleter!.complete(newAccess);
      return newAccess;
    } catch (error) {
      // Any failure: wipe tokens and bounce the user to login.
      await _tokenRepository.clearTokens();
      _refreshCompleter!.complete(null);
      _onUnauthorized?.call();
      return null;
    }
  }

  /// Replays the failed request with the fresh token (that _dio's onRequest
  /// already attached on the retry) and resolves the interceptor.
  Future<void> _retryOriginalRequest(
    RequestOptions original,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      // Ensure the retry carries the new token even if another request's
      // onRequest already ran.
      final freshToken = await _tokenRepository.getAccessToken();
      if (freshToken != null && freshToken.isNotEmpty) {
        original.headers['Authorization'] = 'Bearer $freshToken';
      }
      final response = await _dio.fetch(original);
      return handler.resolve(response);
    } catch (e) {
      return handler.reject(
        e is DioException
            ? e
            : DioException.connectionError(
                requestOptions: original,
                reason: 'Retry failed: $e',
              ),
      );
    }
  }
}
