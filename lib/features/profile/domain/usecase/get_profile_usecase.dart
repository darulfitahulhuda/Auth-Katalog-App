import 'package:auth_katalog_app/core/usecase/usecase.dart';
import 'package:auth_katalog_app/core/utils/typedef.dart';
import 'package:auth_katalog_app/features/profile/domain/entity/profile_entity.dart';
import 'package:auth_katalog_app/features/profile/domain/repository/profile_repository.dart';

/// Fetches the current user's profile. Business logic lives here, not widgets.
class GetProfileUseCase implements UseCase<ProfileEntity, NoParams> {
  const GetProfileUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  FutureData<ProfileEntity> call(NoParams params) {
    return _repository.getProfile();
  }
}