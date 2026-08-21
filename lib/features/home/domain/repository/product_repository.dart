import 'package:auth_katalog_app/core/utils/typedef.dart';
import 'package:auth_katalog_app/features/home/domain/entity/product_entity.dart';

/// Abstract data-access contract for the product catalog. Implementations
/// live in the data layer; the domain knows nothing about Dio or JSON.
abstract interface class ProductRepository {
  /// Returns a paginated slice of the catalog.
  FutureData<List<ProductEntity>> getProducts({
    required int limit,
    required int skip,
  });

  /// Searches the catalog by keyword.
  FutureData<List<ProductEntity>> searchProducts({required String query});

  /// Fetches a single product by id.
  FutureData<ProductEntity> getProductDetail({required int id});
}