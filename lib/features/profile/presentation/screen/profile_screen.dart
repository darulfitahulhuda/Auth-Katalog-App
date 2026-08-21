import 'package:auth_katalog_app/core/di/providers.dart'
    hide themeModeProvider;
import 'package:auth_katalog_app/core/theme/theme_controller.dart';
import 'package:auth_katalog_app/features/profile/domain/entity/profile_entity.dart';
import 'package:auth_katalog_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom-navigation tab (index 1): shows the authenticated user's profile
/// (fetched via `GET /auth/me` in the profile feature), a theme switcher, and
/// a logout action. Navigation to login happens via GoRouter's redirect when
/// the auth state flips — no manual route push here.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authStateNotifierProvider.notifier).logout();
      // AuthState → unauthenticated → GoRouter redirects to /login.
    }
  }

  Future<void> _pickTheme(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeModeProvider).asData?.value ?? ThemeMode.system;
    // Read the stored value once; the notifier flips live in the background.
    final picked = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Mode Tampilan'),
        children: [
          for (final mode in ThemeMode.values)
            _ThemeOption(
              mode: mode,
              selected: mode == current,
              onTap: () => Navigator.of(context).pop(mode),
            ),
        ],
      ),
    );
    if (picked != null) {
      await ref.read(themeModeProvider.notifier).setMode(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final themeMode =
        ref.watch(themeModeProvider).asData?.value ?? ThemeMode.system;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ProfileError(
          message: error.toString(),
          onRetry: () => ref.invalidate(profileProvider),
        ),
        data: (profile) => _ProfileBody(
          profile: profile,
          themeMode: themeMode,
          onThemeTap: () => _pickTheme(context, ref),
          onLogout: () => _confirmLogout(context, ref),
        ),
      ),
    );
  }
}

/// A single radio row inside the theme picker dialog.
class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (mode) {
      ThemeMode.light => (Icons.light_mode_outlined, 'Terang'),
      ThemeMode.dark => (Icons.dark_mode_outlined, 'Gelap'),
      ThemeMode.system => (Icons.brightness_auto_outlined, 'Ikuti Sistem'),
    };

    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.themeMode,
    required this.onThemeTap,
    required this.onLogout,
  });

  final ProfileEntity profile;
  final ThemeMode themeMode;
  final VoidCallback onThemeTap;
  final VoidCallback onLogout;

  String get _themeLabel => switch (themeMode) {
    ThemeMode.light => 'Terang',
    ThemeMode.dark => 'Gelap',
    ThemeMode.system => 'Ikuti Sistem',
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      children: [
        // --- Avatar + identity card ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: colorScheme.primaryContainer,
                    backgroundImage: profile.image.isNotEmpty
                        ? NetworkImage(profile.image)
                        : null,
                    child: profile.image.isNotEmpty
                        ? null
                        : Icon(
                            Icons.person,
                            size: 48,
                            color: colorScheme.onPrimaryContainer,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.displayName,
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${profile.username}',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // --- Settings group ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    themeMode == ThemeMode.dark
                        ? Icons.dark_mode_outlined
                        : themeMode == ThemeMode.light
                        ? Icons.light_mode_outlined
                        : Icons.brightness_auto_outlined,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Mode Tampilan'),
                  subtitle: Text(_themeLabel),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onThemeTap,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.logout, color: colorScheme.error),
                  title: Text('Logout', style: TextStyle(color: colorScheme.error)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onLogout,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          const Text('Gagal memuat profil'),
          const SizedBox(height: 4),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
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