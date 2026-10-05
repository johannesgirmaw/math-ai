import 'package:axiom/core/error/failure.dart';
import 'package:axiom/core/network/api_client.dart';
import 'package:axiom/core/storage/token_store.dart';
import 'package:axiom/features/auth/data/auth_dto.dart';
import 'package:axiom/features/auth/domain/learner.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

/// Account calls used by the session controller.
abstract class AuthRepository {
  Future<Either<Failure, String>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, String>> signUp({
    required String email,
    required String password,
    required String name,
  });

  Future<Either<Failure, Learner>> me();
}

/// Better Auth and `/api/v1/me` over Dio.
class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository({required this._dio, required this._tokenStore});

  final Dio _dio;
  final TokenStore _tokenStore;

  @override
  Future<Either<Failure, Learner>> me() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/v1/me');
      final data = response.data;
      if (data == null) return left(const UnexpectedFailure());
      return right(AuthDto.fromMe(data));
    } on DioException catch (error) {
      return left(_map(error));
    }
  }

  @override
  Future<Either<Failure, String>> signIn({
    required String email,
    required String password,
  }) {
    return _session('/api/v1/auth/sign-in/email', {
      'email': email,
      'password': password,
    });
  }

  @override
  Future<Either<Failure, String>> signUp({
    required String email,
    required String password,
    required String name,
  }) {
    return _session('/api/v1/auth/sign-up/email', {
      'email': email,
      'password': password,
      'name': name,
    });
  }

  Future<Either<Failure, String>> _session(
    String path,
    Map<String, String> body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      final header = response.headers.value('set-auth-token');
      final bodyToken = response.data?['token'];
      final token = header ?? (bodyToken is String ? bodyToken : null);
      if (token == null || token.isEmpty) {
        return left(const UnexpectedFailure('No session token was returned.'));
      }
      await _tokenStore.write(token);
      return right(token);
    } on DioException catch (error) {
      return left(_map(error));
    }
  }

  Failure _map(DioException error) {
    final status = error.response?.statusCode;
    final message = messageFromResponse(error.response?.data);
    if (status == 401) return UnauthorizedFailure(message);
    if (status == 400 || status == 422) return ValidationFailure(message);
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const NetworkFailure();
    }
    return UnexpectedFailure(message);
  }
}
