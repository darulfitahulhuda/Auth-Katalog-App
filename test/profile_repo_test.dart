import 'package:auth_katalog_app/features/profile/data/datasource/profile_remote_data_source.dart';
import 'package:auth_katalog_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:auth_katalog_app/features/auth/data/datasource/auth_local_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

/// Standalone localStorage fake for the profile repo test.
class _FakeTokenRepo implements AuthLocalDataSource {
  String? token = 'valid-access';
  @override
  Future<String?> getAccessToken() async => token;
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {}
  @override
  Future<void> clearTokens() async {}
}

void main() {
  test('profile repo parses a real /auth/me response', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dummyjson.com'));
    final adapter = DioAdapter(dio: dio);

    adapter.onGet(
      '/auth/me',
      (server) => server.reply(
        200,
        {
          'id': 1,
          'firstName': 'Emily',
          'lastName': 'Johnson',
          'gender': 'female',
          'email': 'emily.johnson@x.dummyjson.com',
          'username': 'emilys',
          'image': 'https://dummyjson.com/icon/emilys/128',
        },
        headers: {'content-type': ['application/json']},
      ),
    );

    final repo = ProfileRepositoryImpl(
      remoteDataSource: ProfileRemoteDataSourceImpl(dio),
      authLocalDataSource: _FakeTokenRepo(),
    );

    final result = await repo.getProfile();

    result.fold(
      (failure) => fail(
        'parse/request failed: ${failure.message} (${failure.runtimeType})',
      ),
      (profile) {
        expect(profile.username, 'emilys');
        expect(profile.displayName, 'Emily Johnson');
        expect(profile.email, 'emily.johnson@x.dummyjson.com');
      },
    );
  });
}