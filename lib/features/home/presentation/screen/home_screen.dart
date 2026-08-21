import 'package:auth_katalog_app/core/di/providers.dart';
import 'package:auth_katalog_app/features/auth/domain/entity/user_entity.dart';
import 'package:auth_katalog_app/features/home/domain/entity/product_entity.dart';
import 'package:auth_katalog_app/features/home/presentation/providers/product_providers.dart';
import 'package:auth_katalog_app/features/home/presentation/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Home tab: profile header, debounced search bar, and a responsive product
/// grid with explicit loading / empty / error ("Coba Lagi") states. No Dio or
/// JSON here — all data flows through the [productListProvider] notifier.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateNotifierProvider).value;
    final productsAsync = ref.watch(productListProvider);
    final notifier = ref.read(productListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog'),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _ProfileHeader(user: user),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: notifier.onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari produk…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(child: _buildProductArea(productsAsync, notifier)),
        ],
      ),
    );
  }

  Widget _buildProductArea(
    AsyncValue<List<ProductEntity>> productsAsync,
    ProductListNotifier notifier,
  ) {
    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _ErrorView(onRetry: notifier.retry),
      data: (products) => products.isEmpty
          ? const _EmptyView()
          : _ProductGrid(
              products: products,
              onRefresh: notifier.refresh,
              onLoadMore: notifier.loadMore,
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.user});

  final UserEntity? user;

  @override
  Widget build(BuildContext context) {
    final userName = user?.displayName ?? 'Pengguna';
    final greeting = 'Halo, ${userName.split(' ').first}';
    final hasAvatar = user != null && user!.image.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: hasAvatar ? NetworkImage(user!.image) : null,
            child: hasAvatar
                ? null
                : const Icon(Icons.person, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '@${user?.username ?? '-'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.products,
    required this.onRefresh,
    required this.onLoadMore,
  });

  final List<ProductEntity> products;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 720 ? 4 : width >= 480 ? 3 : 2;

    /// Tolerant consumer of the (nullable) endpoints.
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          // Infinite scroll: trigger next page near the end of the list.
          if (index >= products.length - 4) onLoadMore();
          return ProductCard(product: products[index]);
        },
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64),
          SizedBox(height: 12),
          Text('Produk tidak ditemukan'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          const Text('Gagal memuat katalog'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}