import 'package:auth_katalog_app/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

typedef FutureData<T> = Future<Either<Failure, T>>;
