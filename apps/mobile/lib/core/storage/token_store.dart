/// Stores the bearer token outside of plain preferences.
abstract class TokenStore {
  Future<String?> read();

  Future<void> write(String token);

  Future<void> delete();
}
