import 'package:auth_katalog_app/core/router/app_router.dart';
import 'package:auth_katalog_app/core/theme/app_theme.dart';
import 'package:auth_katalog_app/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root widget. Consumes riverpod for both routing and theming: MaterialApp
/// gets `theme`/`darkTheme` from [AppTheme] and the active [ThemeMode] from
/// [themeModeProvider].
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Falls back to system while the persisted mode loads / if it errors.
    final activeThemeMode = themeMode.when(
      data: (mode) => mode,
      loading: () => ThemeMode.system,
      error: (_, _) => ThemeMode.system,
    );

    return MaterialApp.router(
      title: 'Auth Katalog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: activeThemeMode,
      routerConfig: router,
    );
  }
}