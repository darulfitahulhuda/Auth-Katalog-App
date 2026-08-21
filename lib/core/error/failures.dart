import 'exceptions.dart';

abstract class Failure implements Exception {
  final int errorCode;
  final String message;
  final dynamic data;

  const Failure({this.errorCode = 0, this.message = "", this.data});

  @override
  String toString() => '$runtimeType: $message';
}

class ServerFailure extends Failure {
  const ServerFailure({super.errorCode, super.message, super.data});

  factory ServerFailure.fromException(ServerException error) {
    return ServerFailure(
      errorCode: error.errorCode,
      message: error.message,
      data: error.data,
    );
  }

  factory ServerFailure.noInternet() {
    return const ServerFailure(
      errorCode: 503,
      message: "No Internet Connection",
    );
  }

  factory ServerFailure.other(dynamic error) {
    return ServerFailure(errorCode: 500, message: error.toString());
  }
}

class CacheFailure extends Failure {
  const CacheFailure({super.errorCode, super.message, super.data});

  factory CacheFailure.fromException(CacheException error) {
    return CacheFailure(errorCode: error.errorCode, message: error.message);
  }

  factory CacheFailure.noAuth() {
    return const CacheFailure(errorCode: 401, message: "No Auth");
  }

  factory CacheFailure.other(dynamic error) {
    return CacheFailure(errorCode: 500, message: error.toString());
  }
}
