import 'package:auth_katalog_app/core/extension/double_extension.dart';
import 'package:auth_katalog_app/features/home/domain/entity/product_entity.dart';
import 'package:auth_katalog_app/features/home/presentation/providers/product_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Full-screen product detail (outside the shell — no bottom nav). The
/// product id comes from the `/product/:id` route parameter; data loads via
/// [productDetailProvider]. No Dio/JSON here.
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  /// Raw route param, e.g. `"7"`. Kept as [String] so the router never
  /// parses ids itself; we convert once, defensively.
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(productId);
    final detailAsync = ref.watch(productDetailProvider(id ?? -1));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Produk')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _DetailError(
          productId: productId,
          onBack: () => context.go('/home'),
        ),
        data: (product) => _DetailBody(product: product),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.product});

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.network(
            product.thumbnail,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const ColoredBox(
              color: Color(0xFFEEEEEE),
              child: Center(
                child: Icon(Icons.image_not_supported_outlined, size: 48),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star_rounded,
                      size: 20, color: Colors.amber[700]),
                  const SizedBox(width: 4),
                  Text(
                    product.rating.toStringAsFixed(1),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.inventory_2_outlined,
                      size: 18, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text('Stok: ${product.stock}',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                product.price.toRupiahFromUsd(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text('Deskripsi', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                product.description,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(product.category)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.productId, required this.onBack});

  final String productId;
  final VoidCallback onBack;

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
          const Text('Gagal memuat detail produk'),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Kembali ke katalog'),
          ),
        ],
      ),
    );
  }
}