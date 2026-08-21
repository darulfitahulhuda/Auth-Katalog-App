import 'package:auth_katalog_app/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

import 'package:auth_katalog_app/core/usecase/usecase.dart';
import 'package:auth_katalog_app/features/auth/domain/repository/auth_repository.dart';

/// Clears the current session and any persisted tokens.
class LogoutUseCase implements UseCase<void, NoParams> {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      await _repository.logout();
      return const Right(null);
    } catch (error) {
      return Left(CacheFailure.other(error));
    }
  }
}
