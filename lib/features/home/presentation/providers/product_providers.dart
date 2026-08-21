import 'dart:async';

import 'package:auth_katalog_app/core/di/providers.dart';
import 'package:auth_katalog_app/features/home/domain/entity/product_entity.dart';
import 'package:auth_katalog_app/features/home/domain/usecase/get_product_detail_usecase.dart';
import 'package:auth_katalog_app/features/home/domain/usecase/get_products_usecase.dart';
import 'package:auth_katalog_app/features/home/domain/usecase/search_products_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// First page size for [productListProvider].
const int productPageSize = 20;

/// Debounce window for the search bar.
const Duration searchDebounceDuration = Duration(milliseconds: 400);

/// Catalog list notifier (pagination, debounced search, pull-to-refresh).
final productListProvider =
    AsyncNotifierProvider<ProductListNotifier, List<ProductEntity>>(
      ProductListNotifier.new,
    );

/// Per-product detail: one [ProductDetailNotifier] instance per product id.
final productDetailProvider =
    AsyncNotifierProvider.family<ProductDetailNotifier, ProductEntity, int>(
      ProductDetailNotifier.new,
    );

/// Paginated catalog list with search debounce and pull-to-refresh.
/// State is [AsyncValue<List<ProductEntity>>]: while a search or refresh is
/// in flight the notifier flips to [AsyncLoading]; errors surface as
/// [AsyncError] carrying a [Failure]. The UI never touches Dio/JSON.
class ProductListNotifier extends AsyncNotifier<List<ProductEntity>> {
  final List<ProductEntity> _items = [];
  Timer? _debounce;
  String _query = '';
  bool _hasMore = true;
  bool _isLoadingMore = false;

  GetProductsUseCase get _getProducts => ref.read(getProductsUseCaseProvider);
  SearchProductsUseCase get _searchProducts =>
      ref.read(searchProductsUseCaseProvider);

  @override
  Future<List<ProductEntity>> build() async {
    return _loadFirstPage();
  }

  /// Number of items already loaded — the next page starts here.
  int get _currentSkip => _items.length;

  /// Attach to the search field's onChanged. Debounces 400ms then either
  /// searches (query non-empty) or restores the full list (emptied).
  void onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(searchDebounceDuration, () {
      final trimmed = query.trim();
      if (trimmed == _query) return;
      _query = trimmed;
      if (_query.isEmpty) {
        _resetToFullList();
      } else {
        _runSearch();
      }
    });
  }

  /// Pull-to-refresh: reloads the current view (search or first page).
  Future<void> refresh() async {
    if (_query.isNotEmpty) {
      await _runSearch();
    } else {
      await _resetToFullList();
    }
  }

  /// Retry after an error. Same as refresh but explicitly leaves [AsyncLoading]
  /// so a stuck error state is replaced.
  Future<void> retry() async {
    state = const AsyncLoading();
    await refresh();
  }

  /// Clears the active search and reloads the full first page. Used by the
  /// empty state's "Clear search" action. Flips to [AsyncLoading] so the UI
  /// shows the spinner while the full list rebuilds.
  Future<void> clearSearch() async {
    _debounce?.cancel();
    _query = '';
    state = const AsyncLoading();
    await _resetToFullList();
  }

  /// Infinite scroll: loads the next page and appends to the current list.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _query.isNotEmpty) return;
    _isLoadingMore = true;
    try {
      final result = await _getProducts(
        GetProductsParams(limit: productPageSize, skip: _currentSkip),
      );
      result.fold(
        (failure) {
          // Silently stop paginating on page-error; the loaded list stays.
          _hasMore = false;
        },
        (products) {
          _items.addAll(products);
          _hasMore = products.length == productPageSize;
          state = AsyncData(List.unmodifiable(_items));
        },
      );
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<List<ProductEntity>> _loadFirstPage() async {
    state = const AsyncLoading();
    _items.clear();
    _hasMore = true;
    final result = await _getProducts(
      GetProductsParams(limit: productPageSize, skip: 0),
    );
    return result.fold((failure) => throw failure, (products) {
      _items.addAll(products);
      _hasMore = products.length == productPageSize;
      return List.unmodifiable(_items);
    });
  }

  Future<void> _resetToFullList() async {
    final result = await _getProducts(
      GetProductsParams(limit: productPageSize, skip: 0),
    );
    result.fold((failure) => state = AsyncError(failure, failure.stackTrace), (
      products,
    ) {
      _items
        ..clear()
        ..addAll(products);
      _hasMore = products.length == productPageSize;
      state = AsyncData(List.unmodifiable(_items));
    });
  }

  Future<void> _runSearch() async {
    state = const AsyncLoading();
    final result = await _searchProducts(SearchProductsParams(_query));
    result.fold((failure) => state = AsyncError(failure, failure.stackTrace), (
      products,
    ) {
      _items
        ..clear()
        ..addAll(products);
      _hasMore = false;
      state = AsyncData(List.unmodifiable(_items));
    });
  }
}

/// Fetches a single product by id. One notifier instance per id (family).
class ProductDetailNotifier extends AsyncNotifier<ProductEntity> {
  ProductDetailNotifier(this._productId);

  final int _productId;

  GetProductDetailUseCase get _getDetail =>
      ref.read(getProductDetailUseCaseProvider);

  @override
  Future<ProductEntity> build() async {
    state = const AsyncLoading();
    final result = await _getDetail(GetProductDetailParams(_productId));
    return result.fold((failure) => throw failure, (product) => product);
  }

  /// Retry after an error: flips to [AsyncLoading] then invalidates this
  /// instance so [build] re-runs.
  Future<void> retry() async {
    state = const AsyncLoading();
    ref.invalidateSelf();
  }
}
