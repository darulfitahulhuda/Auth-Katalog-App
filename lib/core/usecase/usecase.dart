import 'package:auth_katalog_app/core/error/failures.dart';
import 'package:auth_katalog_app/core/utils/typedef.dart';

/// Base contract every domain use case implements: takes [Params], returns
/// either a [Failure] or the successful [T], never throws.
abstract class UseCase<T, Params> {
  const UseCase();

  FutureData<T> call(Params params);
}

/// Marker params for use cases that don't need any input.
class NoParams {
  const NoParams();
}
