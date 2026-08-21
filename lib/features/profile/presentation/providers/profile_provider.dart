import 'package:auth_katalog_app/core/di/providers.dart';
import 'package:auth_katalog_app/core/usecase/usecase.dart';
import 'package:auth_katalog_app/features/profile/domain/entity/profile_entity.dart';
import 'package:auth_katalog_app/features/profile/domain/usecase/get_profile_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches the authenticated user's profile via `GET /auth/me`. One [ProfileNotifier]
/// instance shared app-wide (home header + profile tab consume the same state).
/// Errors surface as [AsyncError] carrying a [Failure]; consumers show
/// loading/empty/error states.
final profileProvider = AsyncNotifierProvider<ProfileNotifier, ProfileEntity>(
  ProfileNotifier.new,
);

class ProfileNotifier extends AsyncNotifier<ProfileEntity> {
  GetProfileUseCase get _getProfile => ref.read(getProfileUseCaseProvider);

  @override
  Future<ProfileEntity> build() async {
    state = const AsyncLoading();
    final result = await _getProfile(const NoParams());
    return result.fold((failure) => throw failure, (profile) => profile);
  }

  /// Reloads the profile after an error: flips to [AsyncLoading] so the UI
  /// shows the spinner, then rebuilds via invalidation.
  Future<void> retry() async {
    state = const AsyncLoading();
    ref.invalidateSelf();
  }
}
