import 'package:auth_katalog_app/core/error/failures.dart';
import 'package:auth_katalog_app/core/network/network_info.dart';
import 'package:auth_katalog_app/core/utils/typedef.dart';
import 'package:auth_katalog_app/features/home/data/datasource/product_remote_data_source.dart';
import 'package:auth_katalog_app/features/home/domain/entity/product_entity.dart';
import 'package:auth_katalog_app/features/home/domain/repository/product_repository.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

/// Implements [ProductRepository] by composing [ProductRemoteDataSource] and
/// [NetworkInfo]. Maps transport/Dio errors to [Failure]s, differentiating
/// offline (no connectivity) from server errors.
class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl({
    required ProductRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  }) : _remoteDataSource = remoteDataSource,
       _networkInfo = networkInfo;

  final ProductRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  @override
  FutureData<List<ProductEntity>> getProducts({
    required int limit,
    required int skip,
  }) {
    return _run(() async {
      final models = await _remoteDataSource.getProducts(
        limit: limit,
        skip: skip,
      );
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  FutureData<List<ProductEntity>> searchProducts({
    required String query,
  }) {
    return _run(() async {
      final models = await _remoteDataSource.searchProducts(query: query);
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  FutureData<ProductEntity> getProductDetail({required int id}) {
    return _run(
      () async => (await _remoteDataSource.getProductById(id: id)).toEntity(),
    );
  }

  /// Runs a datasource call, mapping every failure mode to a [Failure].
  /// Returns a [Failure.network] when the device is offline (checked before
  /// hitting the wire and again from transport errors), otherwise a
  /// [Failure.server] for HTTP errors or an unexpected failure.
  FutureData<T> _run<T>(Future<T> Function() action) async {
    final connected = await _networkInfo.isConnected;
    if (!connected) {
      return Left(
        Failure.network(
          'Tidak ada koneksi internet. Periksa koneksi Anda.',
          StackTrace.current,
        ),
      );
    }

    try {
      return Right(await action());
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return Left(
          Failure.network('Tidak ada koneksi internet.', error.stackTrace),
        );
      }
      return Left(Failure.server(_extractMessage(error), error.stackTrace));
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