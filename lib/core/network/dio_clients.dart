import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// Builds the single [Dio] instance the app registers in DI. Kept as a
/// factory function (rather than a class) since there's no per-call state to
/// hold beyond what [Dio] itself already manages.
Dio createDioClient({required String baseUrl}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      PrettyDioLogger(requestBody: true, requestHeader: true),
    );
  }

  return dio;
}
