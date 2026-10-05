import 'package:axiom/core/error/failure.dart';
import 'package:axiom/core/storage/token_store.dart';
import 'package:axiom/features/auth/application/auth_providers.dart';
import 'package:axiom/features/auth/data/auth_repository.dart';
import 'package:axiom/features/auth/domain/learner.dart';
import 'package:axiom/features/auth/presentation/sign_in_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.onCall);

  final void Function() onCall;

  @override
  Future<Either<Failure, Learner>> me() {
    onCall();
    return Future.error(StateError('me should not be called'));
  }

  @override
  Future<Either<Failure, String>> signIn({
    required String email,
    required String password,
  }) {
    onCall();
    return Future.error(StateError('signIn should not be called'));
  }

  @override
  Future<Either<Failure, String>> signUp({
    required String email,
    required String password,
    required String name,
  }) {
    onCall();
    return Future.error(StateError('signUp should not be called'));
  }
}

class _MemoryTokenStore implements TokenStore {
  String? value;

  @override
  Future<void> delete() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async => value = token;
}

void main() {
  testWidgets('empty email does not call the repository', (tester) async {
    var called = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeAuthRepository(() => called = true),
          ),
          tokenStoreProvider.overrideWithValue(_MemoryTokenStore()),
        ],
        child: const MaterialApp(home: SignInPage()),
      ),
    );

    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pump();

    expect(find.text('Enter your email.'), findsOneWidget);
    expect(called, isFalse);
  });
}
