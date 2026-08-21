import 'package:flutter/material.dart';

/// Standalone full-screen product detail (outside the shell — no bottom nav).
/// The product id comes from the `/product/:id` route parameter.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Produk')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'Produk #$productId',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Data produk akan dimuat dari katalog.'),
          ],
        ),
      ),
    );
  }
}