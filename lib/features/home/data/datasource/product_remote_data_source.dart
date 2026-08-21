import 'package:auth_katalog_app/features/home/data/model/product_model.dart';
import 'package:auth_katalog_app/features/home/data/model/product_response_model.dart';
import 'package:dio/dio.dart';

/// Raw API calls to the dummyjson catalog. The ONLY place product code
/// touches Dio's HTTP layer. Domain/presentation never import this.
abstract interface class ProductRemoteDataSource {
  /// Paginated slice of the catalog: `/products?limit=..&skip=..`.
  Future<List<ProductModel>> getProducts({
    required int limit,
    required int skip,
  });

  /// `GET /products/search?q=..`.
  Future<List<ProductModel>> searchProducts({required String query});

  /// `GET /products/{id}`.
  Future<ProductModel> getProductById({required int id});
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  const ProductRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<ProductModel>> getProducts({
    required int limit,
    required int skip,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/products',
      queryParameters: {'limit': limit, 'skip': skip},
    );
    return ProductResponseModel.fromJson(response.data!).products;
  }

  @override
  Future<List<ProductModel>> searchProducts({required String query}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/products/search',
      queryParameters: {'q': query},
    );
    return ProductResponseModel.fromJson(response.data!).products;
  }

  @override
  Future<ProductModel> getProductById({required int id}) async {
    final response = await _dio.get<Map<String, dynamic>>('/products/$id');
    return ProductModel.fromJson(response.data!);
  }
}