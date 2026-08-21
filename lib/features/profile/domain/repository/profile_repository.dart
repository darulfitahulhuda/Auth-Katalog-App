import 'package:auth_katalog_app/core/utils/typedef.dart';
import 'package:auth_katalog_app/features/profile/domain/entity/profile_entity.dart';

/// Abstract data-access contract for the authenticated user's profile.
/// Implementations live in the data layer; knows nothing about Dio or JSON.
abstract interface class ProfileRepository {
  /// Fetches the current user's profile via `GET /auth/me` (protected).
  FutureData<ProfileEntity> getProfile();
}