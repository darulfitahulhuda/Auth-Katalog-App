import 'package:auth_katalog_app/core/usecase/usecase.dart';
import 'package:auth_katalog_app/core/utils/typedef.dart';
import 'package:auth_katalog_app/features/auth/domain/entity/user_entity.dart';
import 'package:auth_katalog_app/features/auth/domain/repositories/auth_repository.dart';

/// Fetches the authenticated user's profile.
class GetProfileUseCase implements UseCase<UserEntity, NoParams> {
  const GetProfileUseCase(this._repository);

  final AuthRepository _repository;

  @override
  FutureData<UserEntity> call(NoParams params) => _repository.getProfile();
}
