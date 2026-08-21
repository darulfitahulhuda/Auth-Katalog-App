import 'package:auth_katalog_app/core/usecase/usecase.dart';
import 'package:auth_katalog_app/core/utils/typedef.dart';
import 'package:auth_katalog_app/features/home/domain/entity/product_entity.dart';
import 'package:auth_katalog_app/features/home/domain/repository/product_repository.dart';

/// Params for [GetProductsUseCase].
class GetProductsParams {
  const GetProductsParams({this.limit = 20, this.skip = 0});

  final int limit;
  final int skip;
}

/// Fetches a page of catalog products. Business logic lives here, not widgets.
class GetProductsUseCase implements UseCase<List<ProductEntity>, GetProductsParams> {
  const GetProductsUseCase(this._repository);

  final ProductRepository _repository;

  @override
  FutureData<List<ProductEntity>> call(GetProductsParams params) {
    return _repository.getProducts(
      limit: params.limit,
      skip: params.skip,
    );
  }
}