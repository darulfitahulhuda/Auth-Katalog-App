import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_entity.freezed.dart';

/// Pure domain representation of a catalog product. No JSON, no Dio — the
/// data layer maps its [ProductModel] into this entity via `toEntity()`.
@freezed
abstract class ProductEntity with _$ProductEntity {
  const factory ProductEntity({
    required int id,
    required String title,
    required String description,
    required double price,
    required double? discountPercentage,
    required double rating,
    required int stock,
    required String category,
    required String thumbnail,
    required List<String> images,
  }) = _ProductEntity;
}