import 'package:auth_katalog_app/core/error/exceptions.dart';
import 'package:auth_katalog_app/core/error/failures.dart';
import 'package:auth_katalog_app/core/utils/typedef.dart';
import 'package:auth_katalog_app/features/auth/data/datasource/auth_remote_data_source.dart';
import 'package:auth_katalog_app/features/auth/domain/entity/user_entity.dart';
import 'package:auth_katalog_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:auth_katalog_app/features/auth/domain/repositories/token_repository.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

/// Implements [AuthRepository] by composing [AuthRemoteDataSource] (HTTP) and
/// [TokenRepository] (secure storage). Maps domain errors to [Failure]s.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required TokenRepository tokenRepository,
  }) : _remoteDataSource = remoteDataSource,
       _tokenRepository = tokenRepository;

  final AuthRemoteDataSource _remoteDataSource;
  final TokenRepository _tokenRepository;

  @override
  FutureData<UserEntity> login({
    required String username,
    required String password,
  }) async {
    try {
      final tokens = await _remoteDataSource.login(
        username: username,
        password: password,
      );
      await _tokenRepository.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      // Login response carries only tokens; the profile lives in the profile
      // feature and is fetched separately via `/auth/me`. Emit a lightweight
      // identity so the auth flow stays fast and session-only.
      return Right(
        UserEntity(id: 0, username: username, email: ''),
      );
    } on DioException catch (error) {
      return Left(Failure.server(_extractMessage(error), error.stackTrace));
    } on ServerException catch (error) {
      return Left(Failure.cache(error.message, error.stackTrace));
    } catch (error, stackTrace) {
      return Left(Failure.unexpected(error.toString(), stackTrace));
    }
  }

  @override
  Future<void> logout() async {
    await _tokenRepository.clearTokens();
  }

  @override
  Future<bool> checkAuthStatus() async {
    final access = await _tokenRepository.getAccessToken();
    final refresh = await _tokenRepository.getRefreshToken();
    return access != null && refresh != null;
  }

  String _extractMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return error.message ?? 'Something went wrong';
  }
}
