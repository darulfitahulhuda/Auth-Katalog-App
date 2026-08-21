import 'package:auth_katalog_app/features/auth/data/model/login_request_model.dart';
import 'package:auth_katalog_app/features/auth/data/model/token_model.dart';
import 'package:auth_katalog_app/features/auth/data/model/user_profile_model.dart';
import 'package:dio/dio.dart';

/// Raw API calls to dummyjson.com. The ONLY place auth code touches Dio's
/// HTTP layer. Domain/presentation never import this.
abstract interface class AuthRemoteDataSource {
  Future<TokenModel> login({
    required String username,
    required String password,
  });

  Future<TokenModel> refreshToken({required String refreshToken});

  Future<UserProfileModel> getProfile({required String accessToken});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const _loginPath = '/auth/login';
  static const _refreshPath = '/auth/refresh';
  static const _mePath = '/auth/me';

  @override
  Future<TokenModel> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _loginPath,
      data: LoginRequestModel(
        username: username,
        password: password,
      ).toJson(),
    );
    return TokenModel.fromJson(response.data!);
  }

  @override
  Future<TokenModel> refreshToken({required String refreshToken}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _refreshPath,
      data: {'refreshToken': refreshToken},
    );
    return TokenModel.fromJson(response.data!);
  }

  @override
  Future<UserProfileModel> getProfile({required String accessToken}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _mePath,
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    return UserProfileModel.fromJson(response.data!);
  }
}