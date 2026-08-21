import 'package:auth_katalog_app/core/di/providers.dart';
import 'package:auth_katalog_app/features/auth/presentation/screen/login_screen.dart';
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
    initialLocation: '/home',
    navigatorKey: _rootNavigatorKey,
    redirect: (context, state) {
      final authAsync = ref.read(authStateNotifierProvider);
      // While the persisted session is still being checked, do not redirect:
      // `AsyncLoading` → value is null but we must NOT bounce to the login
      // screen (that would flash login on every app launch).
      if (authAsync.isLoading) {
        return null;
      }

      final isLoggedIn = authAsync.value != null;
      final isOnLogin = state.matchedLocation == '/login';

      // Not logged in and not on the login screen → send to login.
      if (!isLoggedIn && !isOnLogin) {
        return '/login';
      }
      // Logged in but lingering on the login screen → go home.
      if (isLoggedIn && isOnLogin) {
        return '/home';
      }
      // Otherwise (authenticated browsing anywhere, incl. /home/product/:id)
      // let the navigation proceed untouched.
      return null;
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
    ],
  );

  // Auth state changes (login / logout / session-expired) re-run the redirect,
  // so the router navigates on its own — no manual context.go() needed.
  ref.listen(authStateNotifierProvider, (previous, next) {
    router.refresh();
  });

  return router;
});

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();
