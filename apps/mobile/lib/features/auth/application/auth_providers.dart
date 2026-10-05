import 'package:axiom/core/error/failure.dart';
import 'package:axiom/core/network/api_client.dart';
import 'package:axiom/core/storage/secure_token_store.dart';
import 'package:axiom/core/storage/token_store.dart';
import 'package:axiom/features/auth/data/auth_repository.dart';
import 'package:axiom/features/auth/domain/learner.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

/// API origin passed with `--dart-define=API_BASE_URL=...`.
const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

@Riverpod(keepAlive: true)
TokenStore tokenStore(Ref ref) => SecureTokenStore();

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  return createApiClient(
    baseUrl: apiBaseUrl,
    tokenStore: ref.watch(tokenStoreProvider),
    onUnauthorized: () {
      Future<void>.delayed(Duration.zero, () {
        ref.read(sessionControllerProvider.notifier).signOutLocal();
      });
    },
  );
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return HttpAuthRepository(
    dio: ref.watch(dioProvider),
    tokenStore: ref.watch(tokenStoreProvider),
  );
}

@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  @override
  Future<Learner?> build() async {
    final token = await ref.watch(tokenStoreProvider).read();
    if (token == null || token.isEmpty) return null;
    final result = await ref.watch(authRepositoryProvider).me();
    return result.fold((failure) => null, (learner) => learner);
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) {
    return _openSession(
      () => ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password),
    );
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
  }) {
    return _openSession(
      () => ref
          .read(authRepositoryProvider)
          .signUp(email: email, password: password, name: name),
    );
  }

  Future<void> signOut() async {
    await ref.read(tokenStoreProvider).delete();
    state = const AsyncData(null);
  }

  void signOutLocal() {
    state = const AsyncData(null);
  }

  void replace(Learner learner) {
    state = AsyncData(learner);
  }

  Future<String?> _openSession(
    Future<Either<Failure, String>> Function() request,
  ) async {
    final session = await request();
    switch (session) {
      case Left(value: final failure):
        state = const AsyncData(null);
        return failure.message;
      case Right():
        final learner = await ref.read(authRepositoryProvider).me();
        return learner.fold((failure) {
          state = const AsyncData(null);
          return failure.message;
        }, (value) {
          state = AsyncData(value);
          return null;
        });
    }
  }
}
