import 'package:auth_katalog_app/core/di/providers.dart';
import 'package:auth_katalog_app/features/auth/presentation/screen/login_screen.dart';
import 'package:auth_katalog_app/features/auth/presentation/screen/splash_screen.dart';
import 'package:auth_katalog_app/features/auth/presentation/widgets/main_shell_layout.dart';
import 'package:auth_katalog_app/features/home/presentation/screen/home_screen.dart';
import 'package:auth_katalog_app/features/home/presentation/screen/product_detail_screen.dart';
import 'package:auth_katalog_app/features/profile/presentation/screen/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Routes outside the shell (full-screen, no bottom nav):
/// - `/login`            → login form

/// Protected routes inside [ShellRoute] (with persistent bottom nav):
/// - `/home`    → HomeScreen (index 0)
/// - `/profile` → ProfileScreen (index 1)
/// - `/product/:id`      → product detail
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: "/home",
    navigatorKey: _rootNavigatorKey,
    redirect: (context, state) {
      final authAsync = ref.read(authStateNotifierProvider);
      final isLoggedIn = authAsync.asData?.value != null;

      // BOOT GATE — while the persisted session is still being checked, park
      // on /splash instead of letting /home mount (that was the source of a
      // flash-to-login / blank home on every launch).
      if (authAsync.isLoading) {
        if (state.matchedLocation == '/splash') return null;
        return '/splash';
      }

      if (isLoggedIn) {
        // Data ready: make sure we leave the splash (automatically reached
        // because the redirect re-runs whenever productList/profile change).
        if (state.matchedLocation == '/splash') return '/home';
        return null;
      }

      // Logged in but lingering on the login screen → go home.
      if (isLoggedIn && state.matchedLocation == '/login') {
        return '/home';
      }
      // Anything else not on /login (i.e. unauthenticated) → login.
      return state.matchedLocation == '/login' ? null : '/login';
    },
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShellLayout(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'product/:id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => ProductDetailScreen(
                  productId: state.pathParameters['id'] ?? '',
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
    ],
  );

  // Auth state changes (login / logout / session-expired), and the two data
  // providers the boot gate waits on, all re-run the redirect so the router
  // navigates on its own — no manual context.go() needed.
  ref.listen(authStateNotifierProvider, (previous, next) {
    router.refresh();
  });

  return router;
});

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();
