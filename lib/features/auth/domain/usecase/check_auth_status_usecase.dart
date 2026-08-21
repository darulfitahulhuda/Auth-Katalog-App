import 'package:auth_katalog_app/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

import 'package:auth_katalog_app/core/usecase/usecase.dart';
import 'package:auth_katalog_app/features/auth/domain/repository/auth_repository.dart';

/// Checks whether a valid session exists locally (drives auto-login on
/// app launch). May return an error when the check itself fails.
class CheckAuthStatusUseCase implements UseCase<bool, NoParams> {
  const CheckAuthStatusUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    try {
      final status = await _repository.checkAuthStatus();
      return Right(status);
    } catch (error) {
      return Left(CacheFailure.other(error));
    }
  }
}
