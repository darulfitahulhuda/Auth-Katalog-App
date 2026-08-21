import 'package:auth_katalog_app/core/error/failures.dart';
import 'package:auth_katalog_app/features/home/domain/entity/product_entity.dart';
import 'package:auth_katalog_app/features/home/presentation/providers/product_providers.dart';
import 'package:auth_katalog_app/features/home/presentation/widgets/product_card.dart';
import 'package:auth_katalog_app/features/profile/domain/entity/profile_entity.dart';
import 'package:auth_katalog_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

/// Home tab: profile header, debounced search bar, and a responsive product
/// grid with explicit loading / empty / error ("Coba Lagi") states. No Dio or
/// JSON here — all data flows through the [productListProvider] notifier.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Clears the search field and tells the notifier to reload the first page.
  Future<void> _clearSearch() async {
    _searchController.clear();
    await ref.read(productListProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    // Auth state gates the route; the header shows the richer profile from the
    // profile feature (falls back to a generic greeting while it loads).
    final profileAsync = ref.watch(profileProvider);
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
          _ProfileHeader(profile: profileAsync.value),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: notifier.onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari produk…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, child) => value.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _clearSearch,
                          tooltip: 'Bersihkan pencarian',
                        )
                      : const SizedBox.shrink(),
                ),
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
      error: (error, stackTrace) => _ErrorView(
        isOffline: error is NetworkFailure,
        onRetry: notifier.retry,
      ),
      data: (products) => products.isEmpty
          ? _EmptyView(onClearSearch: _clearSearch)
          : _ProductGrid(
              products: products,
              onRefresh: notifier.refresh,
              onLoadMore: notifier.loadMore,
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.profile});

  final ProfileEntity? profile;

  @override
  Widget build(BuildContext context) {
    final userName = profile?.displayName ?? 'Pengguna';
    final greeting = 'Halo, ${userName.split(' ').first}';
    final hasAvatar = profile != null && profile!.image.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: hasAvatar ? NetworkImage(profile!.image) : null,
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
                  '@${profile?.username ?? '-'}',
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
  const _EmptyView({required this.onClearSearch});

  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            'assets/lotties/empty.json',
            height: 180,
          ),
          const SizedBox(height: 8),
          const Text('Produk tidak ditemukan'),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onClearSearch,
            icon: const Icon(Icons.search_off),
            label: const Text('Bersihkan pencarian'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.isOffline, required this.onRetry});

  final bool isOffline;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            isOffline
                ? 'assets/lotties/no_internet.json'
                : 'assets/lotties/empty.json',
            height: 180,
          ),
          const SizedBox(height: 8),
          Text(isOffline ? 'Tidak ada koneksi internet' : 'Gagal memuat katalog'),
          const SizedBox(height: 4),
          Text(
            isOffline
                ? 'Periksa koneksi Anda, lalu coba lagi.'
                : 'Terjadi kesalahan saat memuat data.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
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