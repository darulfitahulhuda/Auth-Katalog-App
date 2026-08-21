import 'package:auth_katalog_app/core/network/interceptors/auth_interceptor.dart';
import 'package:auth_katalog_app/core/network/dio_clients.dart';
import 'package:auth_katalog_app/core/network/network_info.dart';
import 'package:auth_katalog_app/core/theme/shared_preferences_theme_store.dart';
import 'package:auth_katalog_app/core/theme/theme_controller.dart';
import 'package:auth_katalog_app/core/theme/theme_preferences.dart';
import 'package:auth_katalog_app/features/auth/data/datasource/auth_local_data_source.dart';
import 'package:auth_katalog_app/features/auth/data/datasource/auth_remote_data_source.dart';
import 'package:auth_katalog_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:auth_katalog_app/features/auth/domain/entity/user_entity.dart';
import 'package:auth_katalog_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:auth_katalog_app/features/auth/domain/usecase/check_auth_status_usecase.dart';
import 'package:auth_katalog_app/features/auth/domain/usecase/login_usecase.dart';
import 'package:auth_katalog_app/features/auth/domain/usecase/logout_usecase.dart';
import 'package:auth_katalog_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:auth_katalog_app/features/home/data/datasource/product_remote_data_source.dart';
import 'package:auth_katalog_app/features/home/data/repositories/product_repository_impl.dart';
import 'package:auth_katalog_app/features/home/domain/repository/product_repository.dart';
import 'package:auth_katalog_app/features/home/domain/usecase/get_product_detail_usecase.dart';
import 'package:auth_katalog_app/features/home/domain/usecase/get_products_usecase.dart';
import 'package:auth_katalog_app/features/home/domain/usecase/search_products_usecase.dart';
import 'package:auth_katalog_app/features/profile/data/datasource/profile_remote_data_source.dart';
import 'package:auth_katalog_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:auth_katalog_app/features/profile/domain/repository/profile_repository.dart';
import 'package:auth_katalog_app/features/profile/domain/usecase/get_profile_usecase.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _baseUrl = 'https://dummyjson.com';

/// Token storage. Secure storage must never be swapped for SharedPreferences.
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>(
  (ref) => AuthLocalDataSourceImpl(ref.watch(secureStorageProvider)),
);

/// Raw API client wired with PrettyDioLogger (debug only). The single-flight
/// [AuthInterceptor] is attached here so every protected request sends the
/// access token and transparently refreshes on 401. Although the tap
/// interceptor therefore watches [dioProvider], that's fine — it only
/// interacts at request time, never creating a build-time dependency from
/// this provider back on itself.
final dioProvider = Provider<Dio>((ref) {
  final dio = createDioClient(baseUrl: _baseUrl);
  dio.interceptors.add(
    AuthInterceptor(
      authLocalDataSource: ref.watch(authLocalDataSourceProvider),
      dio: dio,
      onUnauthorized: () {
        ref.read(authStateNotifierProvider.notifier).onSessionExpired();
      },
    ),
  );
  return dio;
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    authLocalDataSource: ref.watch(authLocalDataSourceProvider),
  ),
);

// --- Use cases ---
final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);
final logoutUseCaseProvider = Provider<LogoutUseCase>(
  (ref) => LogoutUseCase(ref.watch(authRepositoryProvider)),
);
final checkAuthStatusUseCaseProvider = Provider<CheckAuthStatusUseCase>(
  (ref) => CheckAuthStatusUseCase(ref.watch(authRepositoryProvider)),
);

// --- Auth state ---
final authStateNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, UserEntity?>(AuthNotifier.new);

// --- Theme mode ---
final themeModeProvider =
    AsyncNotifierProvider<ThemeController, ThemeMode>(ThemeController.new);

/// Lazily-obtained shared-preferences store. It's an `AsyncDio`-free Future:
/// `SharedPreferences.getInstance()` is itself async, so the store exposes the
/// whole instance future for callers to await.
final themePreferencesStoreProvider =
    Provider<Future<ThemePreferencesStore>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return SharedPreferencesThemeStore(prefs);
});

// --- Network info ---
final networkInfoProvider = Provider<NetworkInfo>(
  (ref) => NetworkInfoImpl(Connectivity()),
);

// --- Product catalog ---
final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>(
  (ref) => ProductRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepositoryImpl(
    remoteDataSource: ref.watch(productRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  ),
);

final getProductsUseCaseProvider = Provider<GetProductsUseCase>(
  (ref) => GetProductsUseCase(ref.watch(productRepositoryProvider)),
);
final searchProductsUseCaseProvider = Provider<SearchProductsUseCase>(
  (ref) => SearchProductsUseCase(ref.watch(productRepositoryProvider)),
);
final getProductDetailUseCaseProvider = Provider<GetProductDetailUseCase>(
  (ref) => GetProductDetailUseCase(ref.watch(productRepositoryProvider)),
);

// --- Profile (feature) ---
final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>(
  (ref) => ProfileRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(
    remoteDataSource: ref.watch(profileRemoteDataSourceProvider),
    authLocalDataSource: ref.watch(authLocalDataSourceProvider),
  ),
);

final getProfileUseCaseProvider = Provider<GetProfileUseCase>(
  (ref) => GetProfileUseCase(ref.watch(profileRepositoryProvider)),
);
