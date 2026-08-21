import 'package:auth_katalog_app/core/usecase/usecase.dart';
import 'package:auth_katalog_app/core/utils/typedef.dart';
import 'package:auth_katalog_app/features/home/domain/entity/product_entity.dart';
import 'package:auth_katalog_app/features/home/domain/repository/product_repository.dart';

/// Params for [GetProductDetailUseCase].
class GetProductDetailParams {
  const GetProductDetailParams(this.id);

  final int id;
}

/// Fetches a single product by id.
class GetProductDetailUseCase implements UseCase<ProductEntity, GetProductDetailParams> {
  const GetProductDetailUseCase(this._repository);

  final ProductRepository _repository;

  @override
  FutureData<ProductEntity> call(GetProductDetailParams params) {
    return _repository.getProductDetail(id: params.id);
  }
}