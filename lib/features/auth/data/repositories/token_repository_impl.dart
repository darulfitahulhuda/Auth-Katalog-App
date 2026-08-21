import 'package:auth_katalog_app/features/auth/domain/repositories/token_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure token persistence backed by `flutter_secure_storage`.
/// Never use SharedPreferences for tokens.
class TokenRepositoryImpl implements TokenRepository {
  const TokenRepositoryImpl(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  @override
  Future<String?> getAccessToken() => _secureStorage.read(key: _accessTokenKey);

  @override
  Future<String?> getRefreshToken() =>
      _secureStorage.read(key: _refreshTokenKey);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }
}
