import 'package:axiom/core/storage/token_store.dart';
import 'package:dio/dio.dart';

/// Builds the single Dio client used by the app.
Dio createApiClient({
  required String baseUrl,
  required TokenStore tokenStore,
  void Function()? onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Origin': baseUrl},
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStore.read();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await tokenStore.delete();
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ),
  );
  return dio;
}

/// Reads a human message from an API error body.
String messageFromResponse(dynamic data) {
  if (data is Map) {
    final error = data['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    if (data['message'] is String) return data['message'] as String;
  }
  return 'Something went wrong.';
}
