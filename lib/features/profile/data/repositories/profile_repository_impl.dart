import 'package:auth_katalog_app/core/error/failures.dart';
import 'package:auth_katalog_app/core/error/exceptions.dart';
import 'package:auth_katalog_app/core/utils/typedef.dart';
import 'package:auth_katalog_app/features/auth/domain/repositories/token_repository.dart';
import 'package:auth_katalog_app/features/profile/data/datasource/profile_remote_data_source.dart';
import 'package:auth_katalog_app/features/profile/domain/entity/profile_entity.dart';
import 'package:auth_katalog_app/features/profile/domain/repository/profile_repository.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

/// Implements [ProfileRepository] by composing [ProfileRemoteDataSource]
/// (HTTP) and [TokenRepository] (access token). Maps errors to [Failure]s.
class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({
    required ProfileRemoteDataSource remoteDataSource,
    required TokenRepository tokenRepository,
  }) : _remoteDataSource = remoteDataSource,
       _tokenRepository = tokenRepository;

  final ProfileRemoteDataSource _remoteDataSource;
  final TokenRepository _tokenRepository;

  @override
  FutureData<ProfileEntity> getProfile() async {
    try {
      final token = await _tokenRepository.getAccessToken();
      if (token == null) {
        return Left(
          Failure.cache('No authentication token found', StackTrace.current),
        );
      }
      final profile = await _remoteDataSource.getProfile(accessToken: token);
      return Right(profile.toEntity());
    } on DioException catch (error) {
      return Left(Failure.server(_extractMessage(error), error.stackTrace));
    } on ServerException catch (error) {
      return Left(Failure.cache(error.message, error.stackTrace));
    } catch (error, stackTrace) {
      return Left(Failure.unexpected(error.toString(), stackTrace));
    }
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