import 'package:axiom/core/storage/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// [TokenStore] backed by the platform keychain or keystore.
class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'axiom_bearer_token';
  final FlutterSecureStorage _storage;

  @override
  Future<void> delete() => _storage.delete(key: _key);

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);
}
