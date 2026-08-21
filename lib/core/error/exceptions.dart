/// Thrown by data sources when a remote/server call fails.
class ServerException implements Exception {
  const ServerException([
    this.message = 'A server error occurred',
    this.stackTrace = StackTrace.empty,
  ]);

  final String message;
  final StackTrace stackTrace;
}

/// Thrown by data sources when a local cache read/write fails.
class CacheException implements Exception {
  const CacheException([
    this.message = 'A cache error occurred',
    this.stackTrace = StackTrace.empty,
  ]);

  final String message;
  final StackTrace stackTrace;
}

/// Thrown when there is no network connectivity for a call that requires it.
class NetworkException implements Exception {
  const NetworkException([
    this.message = 'No network connection',
    this.stackTrace = StackTrace.empty,
  ]);

  final String message;
  final StackTrace stackTrace;
}
