import 'package:auth_katalog_app/core/usecase/usecase.dart';
import 'package:auth_katalog_app/core/utils/typedef.dart';
import 'package:auth_katalog_app/features/home/domain/entity/product_entity.dart';
import 'package:auth_katalog_app/features/home/domain/repository/product_repository.dart';

/// Params for [SearchProductsUseCase].
class SearchProductsParams {
  const SearchProductsParams(this.query);

  final String query;
}

/// Searches the catalog by keyword.
class SearchProductsUseCase implements UseCase<List<ProductEntity>, SearchProductsParams> {
  const SearchProductsUseCase(this._repository);

  final ProductRepository _repository;

  @override
  FutureData<List<ProductEntity>> call(SearchProductsParams params) {
    return _repository.searchProducts(query: params.query);
  }
}