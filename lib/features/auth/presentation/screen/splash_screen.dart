import 'package:auth_katalog_app/core/di/providers.dart';
import 'package:auth_katalog_app/features/home/presentation/providers/product_providers.dart';
import 'package:auth_katalog_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Boot gate while the persisted session is checked. Waits for the session
/// AND prefetches the catalog + profile so `/home` mounts with data
/// already present — no first-frame spinner, no blank header.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kick off the session check + prefetch eagerly (cheap, non-blocking).
    // Watching starts each provider's build; the router gate (see
    // app_router.dart) keeps us here until ALL have produced data.
    ref.watch(authStateNotifierProvider);
    ref.watch(productListProvider);
    ref.watch(profileProvider);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Brand mark before navigation hands off to /home.
            Icon(Icons.shopping_bag, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}