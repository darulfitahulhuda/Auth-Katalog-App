import 'package:auth_katalog_app/core/network/auth_interceptor.dart';
import 'package:auth_katalog_app/core/network/dio_clients.dart';
import 'package:auth_katalog_app/core/network/network_info.dart';
import 'package:auth_katalog_app/features/auth/data/datasource/auth_remote_data_source.dart';
import 'package:auth_katalog_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:auth_katalog_app/features/auth/data/repositories/token_repository_impl.dart';
import 'package:auth_katalog_app/features/auth/domain/entity/user_entity.dart';
import 'package:auth_katalog_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:auth_katalog_app/features/auth/domain/repositories/token_repository.dart';
import 'package:auth_katalog_app/features/auth/domain/usecase/check_auth_status_usecase.dart';
import 'package:auth_katalog_app/features/auth/domain/usecase/get_profile_usecase.dart';
import 'package:auth_katalog_app/features/auth/domain/usecase/login_usecase.dart';
import 'package:auth_katalog_app/features/auth/domain/usecase/logout_usecase.dart';
import 'package:auth_katalog_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:auth_katalog_app/features/home/data/datasource/product_remote_data_source.dart';
import 'package:auth_katalog_app/features/home/data/repositories/product_repository_impl.dart';
import 'package:auth_katalog_app/features/home/domain/repository/product_repository.dart';
import 'package:auth_katalog_app/features/home/domain/usecase/get_product_detail_usecase.dart';
import 'package:auth_katalog_app/features/home/domain/usecase/get_products_usecase.dart';
import 'package:auth_katalog_app/features/home/domain/usecase/search_products_usecase.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _baseUrl = 'https://dummyjson.com';

/// Token storage. Secure storage must never be swapped for SharedPreferences.
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final tokenRepositoryProvider = Provider<TokenRepository>(
  (ref) => TokenRepositoryImpl(ref.watch(secureStorageProvider)),
);

/// Raw API client wired with PrettyDioLogger (debug only).
final dioProvider = Provider<Dio>((ref) => createDioClient(baseUrl: _baseUrl));

/// The auth interceptor injected into the main [dioProvider].
final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthInterceptor(
    tokenRepository: ref.watch(tokenRepositoryProvider),
    dio: dio,
    onUnauthorized: () {
      // Signal the app-level provider to land on the login screen.
      ref.read(authStateNotifierProvider.notifier).onSessionExpired();
    },
  );
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    tokenRepository: ref.watch(tokenRepositoryProvider),
  ),
);

// --- Use cases ---
final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);
final logoutUseCaseProvider = Provider<LogoutUseCase>(
  (ref) => LogoutUseCase(ref.watch(authRepositoryProvider)),
);
final getProfileUseCaseProvider = Provider<GetProfileUseCase>(
  (ref) => GetProfileUseCase(ref.watch(authRepositoryProvider)),
);
final checkAuthStatusUseCaseProvider = Provider<CheckAuthStatusUseCase>(
  (ref) => CheckAuthStatusUseCase(ref.watch(authRepositoryProvider)),
);

// --- Auth state ---
final authStateNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, UserEntity?>(AuthNotifier.new);

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
