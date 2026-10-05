import 'dart:typed_data';

import 'package:axiom/core/error/failure.dart';
import 'package:axiom/core/storage/token_store.dart';
import 'package:axiom/features/auth/data/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryTokenStore implements TokenStore {
  @override
  Future<void> delete() async {}

  @override
  Future<String?> read() async => 'stale';

  @override
  Future<void> write(String token) async {}
}

class _FixedAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"error":{"code":"unauthorized","message":"Sign in required."}}',
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  test('401 maps to UnauthorizedFailure', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = _FixedAdapter();
    final repository = HttpAuthRepository(
      dio: dio,
      tokenStore: _MemoryTokenStore(),
    );

    final result = await repository.me();

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<UnauthorizedFailure>()),
      (_) => fail('expected unauthorized'),
    );
  });
}
