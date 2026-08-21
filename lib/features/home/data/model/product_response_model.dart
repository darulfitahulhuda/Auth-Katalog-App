import 'package:auth_katalog_app/features/home/data/model/product_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_response_model.freezed.dart';
part 'product_response_model.g.dart';

/// Envelope returned by `GET /products` and `GET /products/search`:
/// `{ "products": [...], "total": n, "skip": s, "limit": l }`.
@freezed
abstract class ProductResponseModel with _$ProductResponseModel {
  const ProductResponseModel._();

  const factory ProductResponseModel({
    @JsonKey(name: 'products') required List<ProductModel> products,
    @JsonKey(name: 'total') required int total,
    @JsonKey(name: 'skip') required int skip,
    @JsonKey(name: 'limit') required int limit,
  }) = _ProductResponseModel;

  factory ProductResponseModel.fromJson(Map<String, Object?> json) =>
      _$ProductResponseModelFromJson(json);
}