import 'package:auth_katalog_app/core/error/exceptions.dart';
import 'package:auth_katalog_app/core/error/failures.dart';
import 'package:auth_katalog_app/core/utils/typedef.dart';
import 'package:auth_katalog_app/features/auth/data/datasource/auth_remote_data_source.dart';
import 'package:auth_katalog_app/features/auth/domain/entity/user_entity.dart';
import 'package:auth_katalog_app/features/auth/domain/repository/auth_repository.dart';
import 'package:auth_katalog_app/features/auth/domain/repository/token_repository.dart';
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
      final profile = await _remoteDataSource.getProfile(
        accessToken: tokens.accessToken,
      );
      return Right(profile.toEntity());
    } on DioException catch (error) {
      return Left(
        ServerFailure.fromException(
          ServerException(
            errorCode: error.response?.statusCode ?? 0,
            message: _extractMessage(error),
          ),
        ),
      );
    } on ServerException catch (error) {
      return Left(ServerFailure.fromException(error));
    } catch (error) {
      return Left(CacheFailure.other(error));
    }
  }

  @override
  Future<void> logout() async {
    await _tokenRepository.clearTokens();
  }

  @override
  FutureData<UserEntity> getProfile() async {
    try {
      final token = await _tokenRepository.getAccessToken();
      if (token == null) {
        return Left(CacheFailure.noAuth());
      }
      final profile = await _remoteDataSource.getProfile(accessToken: token);
      return Right(profile.toEntity());
    } on DioException catch (error) {
      return Left(
        ServerFailure.fromException(
          ServerException(
            errorCode: error.response?.statusCode ?? 0,
            message: _extractMessage(error),
          ),
        ),
      );
    } on ServerException catch (error) {
      return Left(ServerFailure.fromException(error));
    } catch (error) {
      return Left(CacheFailure.other(error));
    }
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
