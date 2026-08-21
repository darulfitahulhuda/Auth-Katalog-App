import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Shared error/empty state used across features (home catalog, product detail,
/// profile). Distinguishes offline (`NetworkFailure`) from server errors,
/// renders the matching Lottie, and supports both a retry button and
/// pull-to-refresh (the body is always scrollable so [RefreshIndicator] works).
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.isOffline,
    required this.onRetry,
    this.onPullRefresh,
    this.title,
    this.message,
  });

  /// Whether the failure is a network/connectivity issue.
  final bool isOffline;

  /// Retry button action.
  final VoidCallback onRetry;

  /// Optional pull-to-refresh handler (same [RefreshIndicator] contract as
  /// grids). When omitted only the retry button is shown.
  final Future<void> Function()? onPullRefresh;

  /// Optional title override (defaults to offline/server wording).
  final String? title;

  /// Optional secondary line override.
  final String? message;

  @override
  Widget build(BuildContext context) {
    // Pull-to-refresh needs a scrollable that reaches full height even when
    // content is short; ConstrainedBox guarantees the gesture area fills.
    final body = LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
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
                Text(
                  title ??
                      (isOffline
                          ? 'Tidak ada koneksi internet'
                          : 'Gagal memuat data'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    message!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final onRefresh = onPullRefresh;
    return onRefresh == null ? body : RefreshIndicator(onRefresh: onRefresh, child: body);
  }
}