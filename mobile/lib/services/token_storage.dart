import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  const TokenStorage();

  static const String _accessTokenKey = 'access_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> saveToken(String token) {
    return _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> readToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<bool> hasToken() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clear() {
    return _storage.delete(key: _accessTokenKey);
  }
}
