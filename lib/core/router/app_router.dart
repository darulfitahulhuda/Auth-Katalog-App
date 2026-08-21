import 'package:auth_katalog_app/core/di/providers.dart';
import 'package:auth_katalog_app/features/auth/presentation/providers/auth_state.dart';
import 'package:auth_katalog_app/features/auth/presentation/screen/home_screen.dart';
import 'package:auth_katalog_app/features/auth/presentation/screen/login_screen.dart';
import 'package:auth_katalog_app/features/auth/presentation/screen/product_detail_screen.dart';
import 'package:auth_katalog_app/features/auth/presentation/screen/profile_screen.dart';
import 'package:auth_katalog_app/features/auth/presentation/widgets/main_shell_layout.dart';
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
      final authState = ref.read(authStateNotifierProvider).value;
      final isLoginRoute = state.matchedLocation == '/login';

      // Still loading the initial check — stay put.
      if (authState == null ||
          authState is AuthInitial ||
          authState is AuthLoading) {
        return null;
      }

      // Authenticated users never see the login screen.
      if (authState is AuthAuthenticated && isLoginRoute) {
        return '/home';
      }

      // Unauthenticated/errored users are forced onto the login screen.
      if (authState is AuthUnauthenticated || authState is AuthError) {
        return isLoginRoute ? null : '/login';
      }
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
