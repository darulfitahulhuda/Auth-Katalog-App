/// Abstract contract for secure token storage. Implemented in the data layer
/// with `flutter_secure_storage`; the domain and interceptor depend only on
/// this interface.
abstract interface class TokenRepository {
  Future<String?> getAccessToken();

  Future<String?> getRefreshToken();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<void> clearTokens();
}