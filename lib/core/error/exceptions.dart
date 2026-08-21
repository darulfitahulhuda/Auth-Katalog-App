class CacheException implements Exception {
  final int errorCode;
  final String message;

  CacheException({this.errorCode = 0, this.message = ""});
}

class ServerException implements Exception {
  final int errorCode;
  final String message;
  dynamic data;

  ServerException({this.errorCode = 0, this.message = "", this.data});
}
