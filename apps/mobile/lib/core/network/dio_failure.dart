import 'package:axiom/core/error/failure.dart';
import 'package:axiom/core/network/api_client.dart';
import 'package:dio/dio.dart';

/// Turns a Dio error into a [Failure], keeping the status code.
Failure failureFromDio(DioException error) {
  final status = error.response?.statusCode;
  final message = messageFromResponse(error.response?.data);
  if (status == 401) return UnauthorizedFailure(message);
  if (status == 400 || status == 422) return ValidationFailure(message);
  if (status == 409) return HttpFailure(statusCode: 409, message: message);
  if (status != null && status >= 500) {
    return HttpFailure(statusCode: status, message: message);
  }
  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout) {
    return const NetworkFailure();
  }
  if (status != null && status >= 400) {
    return HttpFailure(statusCode: status, message: message);
  }
  return UnexpectedFailure(message);
}
