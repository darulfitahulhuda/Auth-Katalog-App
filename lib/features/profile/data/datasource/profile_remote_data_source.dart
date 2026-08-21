import 'package:auth_katalog_app/features/profile/data/model/profile_model.dart';
import 'package:dio/dio.dart';

/// Raw API calls for the profile feature. The ONLY place this feature sends
/// `GET /auth/me`. Domain/presentation never import this.
abstract interface class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile({required String accessToken});
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const _mePath = '/auth/me';

  @override
  Future<ProfileModel> getProfile({required String accessToken}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _mePath,
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    return ProfileModel.fromJson(response.data!);
  }
}