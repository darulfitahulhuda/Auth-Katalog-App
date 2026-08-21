import 'package:auth_katalog_app/core/di/providers.dart';
import 'package:auth_katalog_app/core/usecase/usecase.dart';
import 'package:auth_katalog_app/features/profile/domain/entity/profile_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches the authenticated user's profile via `GET /auth/me`. Auto-disposes
/// when no widget watches it. Errors surface as [AsyncError] with the failure
/// message; consumers show loading/empty/error states.
final profileProvider = FutureProvider.autoDispose<ProfileEntity>((ref) async {
  final result = await ref.read(getProfileUseCaseProvider)(const NoParams());
  return result.fold(
    (failure) => throw failure,
    (profile) => profile,
  );
});