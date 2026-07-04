import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lưu trữ an toàn token đăng nhập trên thiết bị.
class SecureStorage {
  SecureStorage._();
  static final SecureStorage instance = SecureStorage._();

  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'access_token';

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}
