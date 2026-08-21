import 'package:auth_katalog_app/core/di/providers.dart';
import 'package:auth_katalog_app/core/network/network_info.dart';
import 'package:auth_katalog_app/features/home/presentation/providers/product_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

/// Connectivity that always reports online, so the repo reaches the wire.
class _FakeNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}

void main() {
  test('productListProvider fetches the first catalog page on first listen',
      () async {
    // A real Dio backed by http_mock_adapter (no platform channels).
    final dio = Dio(BaseOptions(baseUrl: 'https://dummyjson.com'));
    final adapter = DioAdapter(dio: dio);
    adapter.onGet(
      '/products',
      (server) => server.reply(
        200,
        {
          'products': [
            {
              'id': 1,
              'title': 'iPhone 9',
              'description': 'An apple mobile which is nothing like apple',
              'price': 549.0,
              'discountPercentage': 12.96,
              'rating': 4.69,
              'stock': 94,
              'category': 'smartphones',
              'thumbnail': 'https://i.dummyjson.com/icon/1.png',
              'images': ['https://i.dummyjson.com/icon/1.png'],
            },
          ],
          'total': 1,
          'skip': 0,
          'limit': 20,
        },
        headers: {'content-type': ['application/json']},
      ),
    );

    // Build the real provider graph; only swap the two seams that would
    // otherwise hit the network or a platform channel. The product chain
    // (productListProvider → use case → repository → dio + networkInfo)
    // touches nothing else — no auth/secure-storage involvement.
    final container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(dio),
        networkInfoProvider.overrideWithValue(_FakeNetworkInfo()),
      ],
    );
    addTearDown(container.dispose);

    // First read triggers build() → _loadFirstPage() → GET /products.
    final asyncBefore = container.read(productListProvider);
    expect(asyncBefore.isLoading, isTrue,
        reason: 'first read must be loading (fetch in flight)');

    await container.read(productListProvider.future);

    final asyncAfter = container.read(productListProvider);
    final products = asyncAfter.value;
    expect(products, isNotNull,
        reason: 'after awaiting the future the list must have data');
    expect(products, hasLength(1));
    expect(products!.first.title, 'iPhone 9');
  });
}