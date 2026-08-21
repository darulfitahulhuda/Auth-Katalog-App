import 'dart:convert';
import 'dart:typed_data';

import 'package:auth_katalog_app/core/network/auth_interceptor.dart';
import 'package:auth_katalog_app/features/auth/domain/repository/token_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [TokenRepository] for tests (no platform channel needed).
class _FakeTokenRepository implements TokenRepository {
  String? access;
  String? refresh;

  @override
  Future<String?> getAccessToken() async => access;

  @override
  Future<String?> getRefreshToken() async => refresh;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    access = null;
    refresh = null;
  }
}

/// Fake [HttpClientAdapter] that:
/// - serves `/auth/refresh` with new (tokens, 200)
/// - serves the first [failuresBeforeSuccess] calls to any protected path
///   with 401, and subsequent calls with 200
/// Tracks how many times refresh was actually called.
class _SequenceAdapter implements HttpClientAdapter {
  _SequenceAdapter({
    required this.protectedPaths,
    this.failuresBeforeSuccess = 1,
  });

  final List<String> protectedPaths;
  final int failuresBeforeSuccess;
  int refreshCalls = 0;
  final Map<String, int> _protectedAttempts = {};

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;

    if (path.contains('/auth/refresh')) {
      refreshCalls++;
      return _body({
        'accessToken': 'fresh-access',
        'refreshToken': 'fresh-refresh',
      });
    }

    if (protectedPaths.any(path.endsWith)) {
      final attempts = _protectedAttempts[path] ?? 0;
      _protectedAttempts[path] = attempts + 1;

      if (attempts < failuresBeforeSuccess && failuresBeforeSuccess > 0) {
        return _body({'message': 'Unauthorized'}, status: 401);
      }
      return _body({'ok': true});
    }

    return _body({'message': 'Not found'}, status: 404);
  }

  ResponseBody _body(Map<String, Object?> json, {int status = 200}) {
    return ResponseBody.fromString(
      jsonEncode(json),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  test('single-flight: 3 concurrent 401s trigger EXACTLY ONE refresh, '
      'then all 3 protected requests retry and succeed', () async {
    final tokenRepo = _FakeTokenRepository()
      ..access = 'expired-access'
      ..refresh = 'valid-refresh';

    final paths = ['/protected/1', '/protected/2', '/protected/3'];
    final adapter = _SequenceAdapter(
      protectedPaths: paths,
      failuresBeforeSuccess: 1,
    );

    final dio = Dio(BaseOptions(baseUrl: 'https://dummyjson.com'))
      ..httpClientAdapter = adapter;

    var unauthorizedRedirects = 0;
    dio.interceptors.add(
      AuthInterceptor(
        tokenRepository: tokenRepo,
        dio: dio,
        onUnauthorized: () => unauthorizedRedirects++,
      ),
    );

    final results = await Future.wait(
      paths.map((p) => dio.get<Map<String, dynamic>>(p)),
    );

    // All three protected requests must eventually succeed.
    expect(results, hasLength(3));
    for (final response in results) {
      expect(response.statusCode, 200);
      expect((response.data as Map)['ok'], isTrue);
    }

    // The single-flight lock guarantees exactly ONE refresh call.
    expect(adapter.refreshCalls, 1);

    // Tokens were swapped to the fresh ones, and no session-expiry fired.
    expect(tokenRepo.access, 'fresh-access');
    expect(tokenRepo.refresh, 'fresh-refresh');
    expect(unauthorizedRedirects, 0);
  });
}
