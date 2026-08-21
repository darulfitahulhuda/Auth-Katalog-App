import 'package:auth_katalog_app/features/home/domain/entity/product_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

/// Raw product JSON from the dummyjson catalog. Serialization (fromJson)
/// lives only in this data-layer class; the domain uses [ProductEntity].
@freezed
abstract class ProductModel with _$ProductModel {
  const ProductModel._();

  const factory ProductModel({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'title') required String title,
    @JsonKey(name: 'description') required String description,
    @JsonKey(name: 'price') required double price,
    @JsonKey(name: 'discountPercentage') double? discountPercentage,
    @JsonKey(name: 'rating') required double rating,
    @JsonKey(name: 'stock') required int stock,
    @JsonKey(name: 'category') required String category,
    @JsonKey(name: 'thumbnail') required String thumbnail,
    @JsonKey(name: 'images') required List<String> images,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, Object?> json) =>
      _$ProductModelFromJson(json);

  /// Maps to the pure domain entity.
  ProductEntity toEntity() => ProductEntity(
    id: id,
    title: title,
    description: description,
    price: price,
    discountPercentage: discountPercentage,
    rating: rating,
    stock: stock,
    category: category,
    thumbnail: thumbnail,
    images: images,
  );
}